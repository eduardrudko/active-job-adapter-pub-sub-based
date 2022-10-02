# frozen_string_literal: true

class LoggerFactory
  class << self
    def _initialize(output = $stdout)
      Logger.new(output)
    end

    def worker_logs
      @worker_logs ||= Message::Worker.new
    end

    def adapter_logs
      @adapter_logs ||= Message::Adapter.new
    end
  end

  module Message
    class Worker
      def booting_up_worker(queue_name)
        "Booting up worker for a queue: #{queue_name}"
      end

      def received_message(event)
        "Received event ID: #{event.message.message_id}. Data: #{event.message.data}, Additional Attributes: #{event.attributes}"
      end

      def worker_exception(exception)
        "#{exception.class} #{exception.message}"
      end
    end
  end
end