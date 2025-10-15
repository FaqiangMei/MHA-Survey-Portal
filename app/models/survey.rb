class Survey < ApplicationRecord
  TRACK_OPTIONS = [
    "Residential",
    "Executive",
    "Online",
    "Hybrid"
  ].freeze

  validates :title, presence: true
  validates :semester, presence: true
  validates :track, allow_blank: true, length: { maximum: 255 }

  has_many :survey_questions, dependent: :destroy
  has_many :questions, through: :survey_questions
  has_many :category_questions, through: :questions
  has_many :categories, -> { distinct }, through: :category_questions
  has_many :student_questions, through: :questions
  has_many :feedbacks, foreign_key: :survey_id, class_name: "Feedback", dependent: :destroy
  has_many :survey_assignments, dependent: :destroy
  has_many :assigned_advisors, through: :survey_assignments, source: :advisor
  has_many :survey_category_tags, dependent: :destroy
  has_many :tagged_categories, through: :survey_category_tags, source: :category
  has_many :audit_logs, class_name: "SurveyAuditLog", inverse_of: :survey, dependent: :destroy

  after_commit :apply_pending_associations, on: %i[create update]

  scope :ordered, -> { order(:id) }

  def assigned_advisor_ids
    if new_record?
      Array(@pending_assigned_advisor_ids)
    else
      survey_assignments.pluck(:advisor_id)
    end
  end

  def assigned_advisor_ids=(ids)
    normalized_ids = normalize_identifier_array(ids)

    if persisted?
      survey_assignments.where.not(advisor_id: normalized_ids).destroy_all
      normalized_ids.each do |advisor_id|
        survey_assignments.find_or_create_by!(advisor_id: advisor_id)
      end
    else
      @pending_assigned_advisor_ids = normalized_ids
    end
  end

  def tagged_category_ids
    if new_record?
      Array(@pending_tagged_category_ids)
    else
      survey_category_tags.pluck(:category_id)
    end
  end

  def tagged_category_ids=(ids)
    normalized_ids = normalize_identifier_array(ids)

    if persisted?
      survey_category_tags.where.not(category_id: normalized_ids).destroy_all
      normalized_ids.each do |category_id|
        survey_category_tags.find_or_create_by!(category_id: category_id)
      end
    else
      @pending_tagged_category_ids = normalized_ids
    end
  end

  private

  def apply_pending_associations
    return unless persisted?

    if defined?(@pending_assigned_advisor_ids) && @pending_assigned_advisor_ids.present?
      ids = @pending_assigned_advisor_ids
      @pending_assigned_advisor_ids = nil
      self.assigned_advisor_ids = ids
    end

    if defined?(@pending_tagged_category_ids) && @pending_tagged_category_ids.present?
      ids = @pending_tagged_category_ids
      @pending_tagged_category_ids = nil
      self.tagged_category_ids = ids
    end
  end

  def normalize_identifier_array(values)
    Array(values).flatten.map(&:presence).compact.map(&:to_i).uniq
  end
end
