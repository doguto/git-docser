class Document < ApplicationRecord
  belongs_to :repository
  belongs_to :user
  
  validates :title, presence: true
  validates :content, presence: true
  validates :pull_request_number, presence: true, numericality: { greater_than: 0 }
end
