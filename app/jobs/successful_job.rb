# frozen_string_literal: true

class SuccessfulJob < ApplicationJob
  queue_as "default"

  def perform
    sleep rand(WORK_TIME + 1) # Does some work
    logger.info"Successful job made some work."
  end
end
