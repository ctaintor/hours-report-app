class Timesheet < ActiveRecord::Base
  belongs_to :user
  belongs_to :report

  has_many :days, dependent: :destroy

  validates_associated :days
  validates :status, inclusion: { in: %w(open submitted reopened) }
  validate :report_open, :if => :reopened?

  accepts_nested_attributes_for :days
  delegate :current?, :start_date, :end_date, :to => :report
  delegate :submitted?, :open?, :reopened?, :to => :status
  delegate :name, :to => :user, :prefix => :user

  def self.build_timesheets(users, start_date, end_date)
    users.map do |user|
      timesheet = new(:user_id => user.id, :status => "open")
      timesheet.days = Day.build_days(start_date, end_date)
      timesheet
    end
  end

  def status
    status = read_attribute(:status) || ''
    status.inquiry
  end

  def total_hours
    summarize("workday")
  end

  def vacation_days
    summarize("vacation")
  end

  def army_reserve_days
    summarize("army")
  end

  def sickness_days
    summarize("sickness")
  end

  def tenbis

  end

  def comments_number
    self.days.select { |d| d.comment? }.count + (self.comments? ? 1 : 0)
  end

  private

  def summarize(day_type)
    days.inject(0) do |sum, day|
      day.day_type == day_type ? sum += day.value : sum
    end
  end

  def report_open
    errors[:base] << "Timesheet cannot be reopened due to submitted report" if self.report.submitted?
  end

  def report_open
    errors[:base] << "Timesheet cannot be reopened due to inactive user" if self.user.inactive?
  end
end
