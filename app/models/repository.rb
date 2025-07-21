class Repository < ApplicationRecord
  belongs_to :user
  has_many :documents, dependent: :destroy
  
  validates :name, presence: true
  validates :url, presence: true
end
