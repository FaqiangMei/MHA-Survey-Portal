# CRUD endpoints for advisor feedback records associated with survey
# responses.
class FeedbacksController < ApplicationController
  before_action :set_feedback, only: %i[ show edit update destroy ]

  # Lists all feedback entries.
  #
  # @return [void]
  def index
    @feedbacks = Feedback.all
  end

  # Displays a single feedback entry.
  #
  # @return [void]
  def show
    @feedback = Feedback.find(params[:id])
  end

  # Renders the new feedback form.
  #
  # @return [void]
  def new
    @survey = Survey.find(params[:survey_id])
    @student = Student.find(params[:student_id])
    @advisor = current_advisor_profile
    @feedback = Feedback.new

  # Load student answers for this survey. Use the student's primary key
  # (`student_id`) and the list of question ids belonging to the survey to
  # make this explicit and avoid join/namespace issues that can return an
  # empty relation in some cases.
  question_ids = @survey.questions.select(:id)
  @responses = StudentQuestion.where(student_id: @student.student_id, question_id: question_ids).includes(question: :category)
    # Build a SurveyResponse PORO so the view can render the same read-only
    # layout students see when viewing their responses.
    @survey_response = SurveyResponse.build(student: @student, survey: @survey)
  end

  # Renders the edit form for existing feedback.
  #
  # @return [void]
  def edit; end

  # Creates a feedback record from submitted attributes.
  #
  # @return [void]
  def create
    @survey = Survey.find(params[:survey_id])
    @student = Student.find(params[:student_id])
    @advisor = current_advisor_profile
    # Support two modes:
    # 1) legacy single-feedback form (feedback_params present)
    # 2) advisor provides per-category ratings via params[:ratings]
  if params[:ratings].present?
      # ratings is expected to be a hash like { "<category_id>" => { "score" => "4", "comment" => "..." }, ... }
      ratings = params.require(:ratings).permit!.to_h

      scores = ratings.values.map { |h| h && h["score"].to_f }.compact.select { |s| s > 0 }
      average = scores.any? ? (scores.sum / scores.size) : nil

      # store the detailed per-category ratings in the comments column as JSON
      details_json = ratings.to_json

      # choose a valid category_id to satisfy DB non-null / FK constraints.
      # Use the first category for this survey as the placeholder.
      placeholder_category_id = @survey.categories.order(:id).first&.id || Category.order(:id).limit(1).pluck(:id).first

      @feedback = Feedback.new(
        survey: @survey,
        student: @student,
        advisor: @advisor,
        average_score: average,
        comments: details_json,
        category_id: placeholder_category_id
      )
    else
      # Support a per-category save when the form posts category_id, average_score, and comments
      if feedback_params[:category_id].present?
        @feedback = Feedback.new(
          survey: @survey,
          student: @student,
          advisor: @advisor,
          category_id: feedback_params[:category_id],
          average_score: feedback_params[:average_score],
          comments: feedback_params[:comments]
        )
      else
        @feedback = Feedback.new(feedback_params.merge(
          survey: @survey,
          student: @student,
          advisor: @advisor,
          category_id: @survey.category_id 
        ))
      end
    end

    

    respond_to do |format|
      if @feedback.save
        format.html { redirect_to @feedback, notice: "Feedback was successfully created." }
        format.json { render :show, status: :created, location: @feedback }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @feedback.errors, status: :unprocessable_entity }
      end
    end
  end

  # Updates an existing feedback entry.
  #
  # @return [void]
  def update
    respond_to do |format|
      if @feedback.update(feedback_params)
        format.html { redirect_to @feedback, notice: "Feedback was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @feedback }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @feedback.errors, status: :unprocessable_entity }
      end
    end
  end

  # Deletes feedback and redirects back to the index.
  #
  # @return [void]
  def destroy
    @feedback.destroy!

    respond_to do |format|
      format.html { redirect_to feedbacks_path, notice: "Feedback was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
  # Finds the feedback referenced in the request.
  #
  # @return [void]
  def set_feedback
    @feedback = Feedback.find(params[:id])
  end

  # Strong parameters for feedback creation/update.
  #
  # @return [ActionController::Parameters]
  def feedback_params
    params.require(:feedback).permit(:advisor_id, :category_id, :surveyresponse_id, :score, :comments, :average_score)
  end

  def set_survey_and_student
    @survey = Survey.find(params[:survey_id])
    @student = Student.find(params[:student_id])
  end
end
