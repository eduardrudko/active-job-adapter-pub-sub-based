# frozen_string_literal: true

require "concurrent/scheduled_task"
require "concurrent/executor/thread_pool_executor"
require "concurrent/utility/processor_counter"

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
      def enqueue(job, attributes={})
        @scheduler.enqueue(job, attributes)
      end

      # Enqueue a job to be performed at a certain time.
      #
      # @param [ActiveJob::Base] job The job to be performed.
      # @param [Float] timestamp The time to perform the job.
      # @param[Hash] attributes to be passed for PubSub event
      def enqueue_at(job, timestamp, attributes={})
        @scheduler.enqueue_at(job, timestamp, attributes)
      end

      # Inspiration was taken from:
      # https://github.com/rails/rails/blob/v6.1.4/activejob/lib/active_job/queue_adapters/async_adapter.rb
      class Scheduler
        DEFAULT_EXECUTOR_OPTIONS = {
          min_threads:     0,
          max_threads:     Concurrent.processor_count,
          auto_terminate:  true,
          idletime:        60, # 1 minute
          max_queue:       0, # unlimited
          fallback_policy: :caller_runs # shouldn't matter -- 0 max queue
        }.freeze

        def initialize(async: true, publisher: Pubsub.new, logger: LoggerFactory._initialize($stdout), **options)
          @logger = logger
          @publisher = publisher
          @async = async
          @liner_executor = Concurrent::ImmediateExecutor.new
          @async_executor = Concurrent::ThreadPoolExecutor.new(DEFAULT_EXECUTOR_OPTIONS.merge(options))
        end

        def enqueue(job, attributes={})
          job.provider_job_id = SecureRandom.uuid
          executor.post do
            @publisher.topic(job.queue_name).publish(JSON.dump(job.serialize), attributes)
          end
        rescue StandardError => e
          @logger.error(e)
        end

        def enqueue_at(job, timestamp, attributes={})
          delay = timestamp - Time.current.to_f
          if delay > 0
            Concurrent::ScheduledTask.execute(delay, executor: executor) do
              enqueue(job, attributes)
            end
          else
            enqueue(job, attributes)
          end
        end

        private

        def executor
          @async ? @async_executor : @liner_executor
        end
      end
    end
  end
end
