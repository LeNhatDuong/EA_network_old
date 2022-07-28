class Result < ActiveRecord::Base
  belongs_to :gateway
  validates :gateway, presence: true

  scope :created_at, -> (created_at) { where(created_at: created_at) }
end
