class User::DataExport < ApplicationRecord
  belongs_to :user
  has_one_attached :zip_file

  validates :status, inclusion: { in: %w[pending processing completed failed] }

  scope :completed, -> { where(status: "completed") }
  scope :pending_or_processing, -> { where(status: %w[pending processing]) }

  def download_available?
    completed? && zip_file.attached?
  end

  def completed?
    status == "completed"
  end

  def failed?
    status == "failed"
  end

  def processing?
    status == "processing"
  end

  def pending?
    status == "pending"
  end
end
