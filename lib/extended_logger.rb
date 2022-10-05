# frozen_string_literal: true

class ExtendedLogger
  class << self
    def get_new(output = $stdout)
      Logger.new(output)
    end

    def worker_logs
      @worker_logs ||= Log::Worker.new
    end

    def adapter_logs
      @adapter_logs ||= Log::Adapter.new
    end
  end

  module Log
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

      def event_acknowledged(event)
        "Event ID: #{event.message.msg_id} has been acknowledged!"
      end
    end
  end
end