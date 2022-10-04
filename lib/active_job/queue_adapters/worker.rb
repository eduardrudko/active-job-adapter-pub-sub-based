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
        success = false
        begin
          if time_to_run?(event)
            ActiveJob::Base.execute(JSON.parse(event.data))
            success = true
          else
            event.modify_ack_deadline!(remaining_time_to_run(event))
          end
        rescue StandardError => e
          @logger.error(LoggerFactory.worker_logs.worker_exception(e))
        ensure
          if success
            event.acknowledge!
            @logger.info(LoggerFactory.worker_logs.event_acknowledged(event))
          end
        end
      end

      def enqueued_at(event)
        timestamp = event.attributes['timestamp']
        timestamp.nil? ? nil : Time.at(timestamp.to_f)
      end

      def remaining_time_to_run(event)
        enqueued_at = enqueued_at(event)
        enqueued_at ? [(enqueued_at - Time.now).to_f.ceil, 0].max : 0
      end

      def time_to_run?(event)
        remaining_time_to_run(event).zero?
      end
    end
  end
end