class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  before_action :authenticate_admin!
  allow_browser versions: :modern

  # Convenience helper to map the logged-in Devise Admin to a Student record
  # (used to determine whether the current user is acting as a student)
  def current_student
    return @current_student if defined?(@current_student)
    if defined?(current_admin) && current_admin.present?
      @current_student = Student.find_by(email: current_admin.email)
    else
      @current_student = nil
    end
  end
  helper_method :current_student
end
