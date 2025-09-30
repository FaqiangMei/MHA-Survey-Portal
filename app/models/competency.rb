class Competency < ApplicationRecord
  validates :name, presence: true

  belongs_to :survey, optional: true
  has_many :questions, dependent: :destroy
  has_many :competency_responses, dependent: :destroy
end
