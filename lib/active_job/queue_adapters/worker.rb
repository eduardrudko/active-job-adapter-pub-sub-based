# frozen_string_literal: true

require_relative "../../logger_factory"

module ActiveJob
  module QueueAdapters
    class Worker
      def initialize(queue_name: "default", logger: LoggerFactory._initialize($stdout))
        @queue_name = queue_name
        @logger = logger
        @pubsub = Pubsub.new
      end

      def start
        @logger.info(LoggerFactory.worker_logs.booting_up_worker(@queue_name))

        subscriber = @pubsub.subscription(@queue_name).listen(threads: { callback: 16 }) do |event|
          @logger.info(LoggerFactory.worker_logs.received_message(event))
          run(event)
        end

        subscriber.on_error do |exception|
          @logger.error(LoggerFactory.worker_logs.worker_exception(exception))
        end

        begin
          subscriber.start

          sleep
        ensure
          subscriber.stop!(10)
        end
      end

      private

      def run(event)
        ActiveJob::Base.execute JSON.parse(event.data)
      rescue StandardError => e
        @logger.error(LoggerFactory.worker_logs.worker_exception(e))
      ensure
        event.acknowledge!
      end
    end
  end
end