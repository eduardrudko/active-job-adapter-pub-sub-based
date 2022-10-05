# frozen_string_literal: true
class ApplicationJob < ActiveJob::Base
  WORK_TIME = 5

  retry_on(StandardError, wait: 5.minutes, attempts: 3) do |job, _error|
    job.enqueue(queue: "morgue-of-#{job.queue_name}")
  end

  def logger
    @logger ||= ExtendedLogger.get_new($stdout)
  end
end
