# frozen_string_literal: true

require_relative "../active_job/queue_adapters/worker"

namespace(:worker) do
  desc("Run the worker")
  task :run, [:queue_name] => :environment do |_task, args|
    ActiveJob::QueueAdapters::Worker.new(queue_name: args[:queue_name]).start
  end
end
