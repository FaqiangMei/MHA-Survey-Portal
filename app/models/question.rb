class Question < ApplicationRecord
  self.primary_key = :question_id

  enum :question_type, {
    multiple_choice: "multiple_choice",
    scale: "scale",
    short_answer: "short_answer",
    evidence: "evidence"
  }, prefix: true

  belongs_to :category
  has_many :question_responses, foreign_key: :question_id, dependent: :destroy
  # optional self-referential association for conditional questions
  belongs_to :depends_on_question, class_name: 'Question', foreign_key: :depends_on_question_id, optional: true

  validates :question, presence: true
  validates :question_order, presence: true
  validates :question_type, presence: true, inclusion: { in: question_types.values }

  # expose reader methods expected by views
  def depends_on_question_id
    self[:depends_on_question_id]
  end

  def depends_on_value
    self[:depends_on_value]
  end

  def required
    self[:required]
  end
end
