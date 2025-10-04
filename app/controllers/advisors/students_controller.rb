module Advisors
  class StudentsController < BaseController
    def index
      @students = load_students
    end

    private

    def load_students
      scope = if current_user.role_admin?
        Student.includes(:user)
      else
        current_advisor_profile&.advisees&.includes(:user) || Student.none
      end

      scope
        .left_joins(:user)
        .includes(survey_responses: [ :survey, { question_responses: :question } ])
        .order(Arel.sql("LOWER(users.name) ASC"))
    end
  end
end
