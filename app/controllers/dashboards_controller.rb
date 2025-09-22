class DashboardsController < ApplicationController
  before_action :authenticate_admin!
  
  def show
    # Default dashboard - redirect based on role
    Rails.logger.debug "Current admin: #{current_admin.inspect}"
    Rails.logger.debug "Current admin role: #{current_admin.role}"
    
    if current_admin.role == 'student'
      redirect_to student_dashboard_path
    elsif current_admin.role == 'advisor'
      redirect_to advisor_dashboard_path
    else
      # Fallback - if no role is set, redirect to student for now
      Rails.logger.debug "No role found, redirecting to student dashboard"
      redirect_to student_dashboard_path
    end
  end

  def student
    # Student dashboard
    Rails.logger.debug "Rendering student dashboard for #{current_admin.email}"
  end

  def advisor
    # Advisor dashboard
    Rails.logger.debug "Rendering advisor dashboard for #{current_admin.email}"
  end
end