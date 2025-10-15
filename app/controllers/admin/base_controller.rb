class Admin::BaseController < ApplicationController
  before_action :require_admin!

  helper_method :current_admin_profile

  private

  def require_admin!
    return if current_user&.role_admin?

    redirect_to dashboard_path, alert: "Access denied. Admin privileges required."
  end

  def current_admin_profile
    current_user&.admin_profile
  end
end
