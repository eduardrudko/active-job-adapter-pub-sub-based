# frozen_string_literal: true

class FailedJob < ApplicationJob
  queue_as "default"

  def perform
    sleep rand(WORK_TIME + 1) # Does some work
    raise StandardError.new("Exception: Job has failed!") # and then fails
  end
end