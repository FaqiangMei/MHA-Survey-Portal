class SurveysController < ApplicationController
  before_action :set_survey, only: %i[ show edit update destroy submit ]

  # GET /surveys or /surveys.json
  def index
    # Show all surveys to the user on the index page
    @surveys = Survey.all.order(:id)
  end

  # GET /surveys/1 or /surveys/1.json
  def show
    # If a student is signed in (via current_admin), collect existing answers so the
    # survey form can pre-fill previously submitted responses for editing/resubmission.
    @existing_answers = {}
    if defined?(current_admin) && current_admin.present?
      student = Student.find_by(email: current_admin.email)
      if student
        # Find the survey_response for this student & survey
        sr = SurveyResponse.find_by(student_id: student.id, survey_id: @survey.id)
        if sr
          # Collect question responses only for this survey_response
          qrs = QuestionResponse.where(surveyresponse_id: sr.id)
          qrs.each do |qr|
            @existing_answers[qr.question_id] = qr.answer
          end

          # Load existing evidence uploads for this student and surveyresponse, grouped by category
          @existing_evidence_by_category = {}
          eus = EvidenceUpload.includes(question_response: { question: :category }).where(student_id: student.id)
          # Filter to only those evidence uploads attached to question_responses that belong to this survey_response
          eus = eus.select { |e| e.question_response&.surveyresponse_id.to_i == sr.id }
          # Group by category id (if available)
          eus.group_by { |e| e.question_response&.question&.category_id }.each do |cid, arr|
            # sort by created_at desc so latest first
            @existing_evidence_by_category[cid] = arr.sort_by { |x| x.created_at || Time.at(0) }.reverse
          end
          # Also group evidence uploads by question id for showing in each question block
          @existing_evidence_by_question = {}
          eus.group_by { |e| e.question_response&.question_id }.each do |qid, arr|
            @existing_evidence_by_question[qid] = arr.sort_by { |x| x.created_at || Time.at(0) }.reverse
          end
          # Pre-compute which questions should be marked required in the UI so view logic is simple
          @computed_required = {}
          @survey.categories.includes(:questions).each do |cat2|
            cat2.questions.each do |qq|
              # If the question has a dependency, it's required only when the dependency is satisfied
              if qq.depends_on_question_id.present?
                dep_qid = qq.depends_on_question_id.to_i
                dep_expected = qq.depends_on_value.to_s
                dep_actual = @existing_answers[dep_qid]
                @computed_required[qq.id] = (dep_actual.to_s == dep_expected)
                next
              end

              is_required = qq.required
              # Default rule for non-conditional questions
              if !is_required
                case qq.question_type
                when "multiple_choice"
                  raw_opts = (qq.answer_options || "").to_s
                  parsed = begin
                    JSON.parse(raw_opts) rescue nil
                  end
                  options = if parsed.is_a?(Array)
                              parsed.map(&:to_s)
                  else
                              raw_opts.gsub(/[\[\]"“”]/, "").split(",").map(&:strip).reject(&:empty?)
                  end
                  normalized = options.map { |o| o.to_s.strip.downcase }
                  # Yes/No multiple choice are NOT required by default
                  is_required = !(normalized == [ "yes", "no" ] || normalized == [ "no", "yes" ])
                else
                  is_required = true
                end
              end
              @computed_required[qq.id] = is_required
            end
          end
        end
      end
    end
  end

  # GET /surveys/new
  def new
    @survey = Survey.new
  end

  # GET /surveys/1/edit
  def edit
  end

  # POST /surveys or /surveys.json
  def create
    @survey = Survey.new(survey_params)

    respond_to do |format|
      if @survey.save
        format.html { redirect_to @survey, notice: "Survey was successfully created." }
        format.json { render :show, status: :created, location: @survey }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @survey.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /surveys/1 or /surveys/1.json
  def update
    respond_to do |format|
      if @survey.update(survey_params)
        format.html { redirect_to @survey, notice: "Survey was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @survey }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @survey.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /surveys/1 or /surveys/1.json
  def destroy
    @survey.destroy!

    respond_to do |format|
      format.html { redirect_to surveys_path, notice: "Survey was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end
  # POST /surveys/1/submit
  def submit
    # identify the acting student: try to match current_admin (Devise) to Student by email
    student = nil
    if defined?(current_admin) && current_admin.present?
      student = Student.find_by(email: current_admin.email)
    elsif defined?(current_user) && current_user.present?
      # tests sign in a User fixture; get the associated Student profile
      # User has_one :student_profile (Student) via student_profile
      student = current_user.student_profile
    end

    unless student
      redirect_to student_dashboard_path, alert: "Student record not found for current user."
      return
    end

  # Find or create survey_response and mark submitted
  survey_response = SurveyResponse.find_or_initialize_by(student_id: student.id, survey_id: @survey.id)
  survey_response.status = SurveyResponse.statuses[:submitted]
  survey_response.advisor_id ||= student.advisor_id
  # Some schemas may not have a semester column on SurveyResponse; only set if present
  if survey_response.respond_to?(:semester)
    survey_response.semester ||= params[:semester]
  end
  survey_response.save!

  # Validate and save answers
  answers = params[:answers] || {}
  # Support both legacy per-question evidence_links and new per-category grouping
  evidence_links = params[:evidence_links] || {}
  evidence_links_by_category = params[:evidence_links_by_category] || {}

    missing_required = []
    # Iterate survey questions directly (categories -> questions)
    @survey.categories.includes(:questions).each do |cat|
      cat.questions.each do |q|
        # Determine if question is required
        is_required = q.required
        # Default rule: for non-conditional questions, most types are required by default
        if !is_required && q.depends_on_question_id.blank? && q.depends_on_value.blank?
          case q.question_type
          when "multiple_choice"
            # If the options are exactly Yes/No (in any order), treat as NOT required by default
            raw_opts = (q.answer_options || "").to_s
            parsed = begin
              JSON.parse(raw_opts) rescue nil
            end
            options = if parsed.is_a?(Array)
                        parsed.map(&:to_s)
            else
                        raw_opts.gsub(/[\[\]"“”]/, "").split(",").map(&:strip).reject(&:empty?)
            end
            normalized = options.map { |o| o.to_s.strip.downcase }
            if normalized == [ "yes", "no" ] || normalized == [ "no", "yes" ]
              is_required = false
            else
              is_required = true
            end
          else
            # all other non-conditional questions default to required unless explicitly set
            is_required = true
          end
        end

        # If conditional, check dependency
        if q.depends_on_question_id.present? && q.depends_on_value.present?
          dep_val = answers[q.depends_on_question_id.to_s]
          next unless dep_val.to_s == q.depends_on_value.to_s
        end

        # Read submitted value from answers[...] (evidence is now submitted as a free-response)
        val = answers[q.id.to_s]

        missing_required << q if is_required && val.blank?
      end
    end

    if missing_required.any?
      flash[:alert] = "Please answer all required questions (marked with *)."
      flash[:missing_required_ids] = missing_required.map(&:id)
      redirect_to survey_path(@survey, missing: missing_required.map(&:id).join(",")) and return
    end

    # Persist answers: ensure QuestionResponse links to surveyresponse
    ActiveRecord::Base.transaction do
      answers.each do |question_id_str, answer_value|
        next unless question_id_str.to_s =~ /^\d+$/
        qid = question_id_str.to_i
  q = Question.find_by(question_id: qid)
        next unless q
        qr = QuestionResponse.find_or_initialize_by(surveyresponse_id: survey_response.id, question_id: qid)
        qr.answer = answer_value
        qr.save!
      end

      # Persist evidence answers that were submitted via answers[<question_id>] for evidence-type questions
      @survey.categories.includes(:questions).each do |cat|
        cat.questions.each do |q|
          next unless q.question_type == "evidence"
          link = answers[q.id.to_s]
          next if link.blank?

          eu = EvidenceUpload.new(student_id: student.id, link: link, created_by: student.id)
          unless eu.valid?
            flash[:alert] = "Invalid evidence link for question #{q.id}: #{eu.errors.full_messages.join(', ')}"
            redirect_to survey_path(@survey) and return
          end

          qr = QuestionResponse.find_or_initialize_by(surveyresponse_id: survey_response.id, question_id: q.id)
          qr.answer = link
          qr.save!

          eu.questionresponse_id = qr.id
          eu.save!
        end
      end

      # Persist legacy per-question evidence links
      evidence_links.each do |question_id_str, link|
        next if link.blank?
        qid = question_id_str.to_i
  q = Question.find_by(question_id: qid)
        next unless q && q.question_type == "evidence"

        eu = EvidenceUpload.new(student_id: student.id, link: link, created_by: student.id)
        unless eu.valid?
          flash[:alert] = "Invalid evidence link for question #{qid}: #{eu.errors.full_messages.join(', ')}"
          redirect_to survey_path(@survey) and return
        end

        qr = QuestionResponse.find_or_initialize_by(surveyresponse_id: survey_response.id, question_id: qid)
        qr.answer = link
        qr.save!

        eu.questionresponse_id = qr.id
        eu.save!
      end

      # Persist new per-category evidence links: attach provided link(s) to that category's evidence question(s)
      evidence_links_by_category.each do |category_id_str, link|
        next if link.blank?
        cid = category_id_str.to_i
        cat = Category.find_by(id: cid)
        next unless cat

        # Find or create an evidence-type question in this category (attach to this category even if question missing)
        eq = cat.questions.find_by(question_type: "evidence")
        if eq.nil?
          # create a simple evidence question to record this link
          next_order = (cat.questions.maximum(:question_order) || 0) + 1
          eq = cat.questions.create!(question: "Upload evidence", question_type: "evidence", question_order: next_order)
        end

        # Validate
        eu = EvidenceUpload.new(student_id: student.id, link: link, created_by: student.id)
        unless eu.valid?
          flash[:alert] = "Invalid evidence link for competency #{cat.name}: #{eu.errors.full_messages.join(', ')}"
          redirect_to survey_path(@survey) and return
        end

        # Ensure a QuestionResponse exists for that evidence question and survey_response
        qr = QuestionResponse.find_or_initialize_by(surveyresponse_id: survey_response.id, question_id: eq.id)
        qr.answer = link
        qr.save!

        eu.questionresponse_id = qr.id
        eu.save!
      end
    end

    redirect_to survey_response_path(survey_response), notice: "Survey submitted successfully!"
  end
  private
    # Use callbacks to share common setup or constraints between actions.
    def set_survey
      @survey = Survey.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def survey_params
      params.require(:survey).permit(:survey_id, :assigned_date, :completion_date, :approval_date, :title, :semester)
    end
end
