class SurveyAuditLog < ApplicationRecord
  ACTIONS = %w[create update delete group_update preview].freeze

  belongs_to :survey, optional: true
  belongs_to :admin, class_name: "Admin", foreign_key: :admin_id, primary_key: :admin_id

  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :metadata, presence: true

  scope :recent_first, -> { order(created_at: :desc) }
end
