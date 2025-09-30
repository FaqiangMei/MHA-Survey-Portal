class EvidenceUpload < ApplicationRecord
  validates :link, presence: true
end
