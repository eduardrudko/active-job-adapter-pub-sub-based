# frozen_string_literal: true

# Simulates running rails server that performs various delayed job work
namespace(:loader) do
  desc("Runs each of job types")
  task demo: :environment do
    logger.info("Demo of job types enqueued")
    SuccessfulJob.perform_later # job enqueued now
    SuccessfulJob.set(wait: 1.minute).perform_later # job enqueued 1 min later
    FailedJob.perform_later # failed job enqueued now
    FailedJob.set(wait: 2.minutes).perform_later # failed job enqueued 2 min later

    sleep # rails serve
  end

  task run: :environment do
    logger.info("Making some load:")
    logger.info("")
    logger.info("")
    logger.info("")
    logger.info("")

    make_load

    sleep # rails serve
  end

  def make_load
    Thread.new do
      while true
        SuccessfulJob.perform_later
        SuccessfulJob.perform_later
        SuccessfulJob.perform_later
        SuccessfulJob.perform_later
        SuccessfulJob.perform_later
        sleep 1 # To make publisher slower than listener
      end
    end

    Thread.new do
      while true
        FailedJob.perform_later
        FailedJob.perform_later
        FailedJob.perform_later
        FailedJob.perform_later
        FailedJob.perform_later
        sleep 1 # To make publisher slower than listener
      end
    end
  end

  def logger
    @logger ||= LoggerFactory._initialize($stdout)
  end
end
