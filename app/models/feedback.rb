class Feedback < ApplicationRecord
  validates :comments, presence: true
  validates :rating, inclusion: { in: 1..5 }, allow_nil: true
end
