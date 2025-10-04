class SurveysController < ApplicationController
  before_action :set_survey, only: %i[ show edit update destroy submit ]

  # GET /surveys or /surveys.json
  def index
    @surveys = Survey.all
  end

  # GET /surveys/1 or /surveys/1.json
  def show
    @survey_response = nil
    @existing_answers = {}

    if current_student
      @survey_response = SurveyResponse.find_by(student_id: current_student.id, survey_id: @survey.id)
      if @survey_response
        @existing_answers = @survey_response.question_responses.index_by(&:question_id)
      end
    end
  end

  # GET /surveys/new
  def new
    @survey = Survey.new
      student = current_student
  # POST /surveys or /surveys.json
  def create
    @survey = Survey.new(survey_params)

    respond_to do |format|
      if @survey.save
      survey_response = SurveyResponse.find_or_initialize_by(student_id: student.id, survey_id: @survey.id)
      survey_response.status = SurveyResponse.statuses[:submitted]
      else
      survey_response.completion_date ||= Date.current
        format.json { render json: @survey.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /surveys/1 or /surveys/1.json
  def update
    respond_to do |format|
        question = @survey.questions.find_by(question_id: qid)
        question ||= Question.find_by(question_id: qid)
        next unless question
        format.html { redirect_to @survey, notice: "Survey was successfully updated.", status: :see_other }
        qr = QuestionResponse.find_or_initialize_by(surveyresponse_id: survey_response.id, question_id: question.question_id)
        qr.answer = answer_value
        qr.save!
    # identify the acting student: try to match current_admin (Devise) to Student by email
    student = nil
    if defined?(current_admin) && current_admin.present?
      student = Student.find_by(email: current_admin.email)
    end

    unless student
      redirect_to student_dashboard_path, alert: "Student record not found for current user."
      return
    end

    # Find or create survey_response and mark submitted
    survey_response = SurveyResponse.find_or_initialize_by(student_id: student.id, survey_id: @survey.id)
    survey_response.status = SurveyResponse.statuses[:submitted]
    survey_response.advisor_id ||= student.advisor_id
    survey_response.semester ||= params[:semester]
    survey_response.save!

    # Save question responses if provided
    answers = params[:answers] || {}
    answers.each do |question_id_str, answer_value|
      # question ids might be 'sample_text' fallback — skip non-integer keys
      next unless question_id_str.to_s =~ /^\d+$/
      qid = question_id_str.to_i
      q = Question.find_by(id: qid)
      next unless q

      # Find or create the competency_response for this survey_response and question's competency
      comp = Competency.find_by(id: q.competency_id)
      comp_resp = nil
      if comp
        comp_resp = CompetencyResponse.find_or_create_by!(surveyresponse_id: survey_response.id, competency_id: comp.id)
      end

      # normalize checkbox arrays into JSON/string
      response_value = answer_value

      # create or update existing question_response scoped to the competency_response
      qr = if comp_resp
             QuestionResponse.find_or_initialize_by(question_id: qid, competencyresponse_id: comp_resp.id)
      else
             # Fallback: if no competency available, store with nil competencyresponse (legacy behavior)
             QuestionResponse.find_or_initialize_by(question_id: qid, competencyresponse_id: nil)
      end
      qr.answer = response_value
      qr.save!
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
      params.require(:survey).permit(:title, :semester)
    end
end
