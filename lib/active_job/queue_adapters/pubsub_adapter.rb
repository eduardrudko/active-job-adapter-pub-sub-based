# frozen_string_literal: true
#
require 'concurrent'

require_relative "../../logger_factory"

module ActiveJob
  module QueueAdapters
    class PubsubAdapter
      def initialize(**options)
        @scheduler = Scheduler.new(options)
      end

      # Enqueue a job to be performed.
      #
      # @param [ActiveJob::Base] job The job to be performed.
      # @param[Hash] attributes to be passed for PubSub event
      def enqueue(job, attributes = {})
        @scheduler.enqueue(job, attributes)
      end

      # Enqueue a job to be performed at a certain time.
      #
      # @param [ActiveJob::Base] job The job to be performed.
      # @param [Float] timestamp The time to perform the job.
      # @param[Hash] attributes to be passed for PubSub event
      def enqueue_at(job, timestamp, attributes = {})
        @scheduler.enqueue_at(job, timestamp, attributes)
      end

      class Scheduler
        def initialize(async: true, publisher: Pubsub.new, logger: LoggerFactory._initialize($stdout))
          @executor = async ? :io : :immediate
          @publisher = publisher
          @logger = logger
        end

        # Enqueues job asynchronously to eliminate any potential delay publishing to Google Cloud
        # @param job[ActiveJob::Base] job The job to be performed.
        # @param[Hash] attributes to be passed for PubSub event
        def enqueue(job, attributes = {})
          job.provider_job_id = SecureRandom.uuid

          promise = Concurrent::Promise.execute(executor: @executor) do
            @publisher.topic(job.queue_name).publish(JSON.dump(job.serialize), attributes)
          end

          # Any PubSub related errors will be caught here
          promise.on_error do |e|
            @logger.error(e)
          end
        end

        # Enqueues job asynchronously passing timestamp to let backend handle scheduled delay
        #
        # @param [ActiveJob::Base] job The job to be performed.
        # @param [Float] timestamp The time to perform the job.
        # @param[Hash] attributes to be passed for PubSub event
        def enqueue_at(job, timestamp, attributes = {})
          enqueue(job, { timestamp: timestamp }.merge(attributes))
        end
      end
    end
  end
end
