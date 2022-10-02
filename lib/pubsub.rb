# frozen_string_literal: true

require("google/cloud/pubsub")

class Pubsub
  # Find or create a topic.
  #
  # @param name [String] The name of the topic to find or create
  # @return [Google::Cloud::PubSub::Topic]
  def topic(name)
    client.topic(name) || client.create_topic(name)
  end

  # Find subscription or subscribe to a new or existing topic
  #
  # @param name [String] The name of the topic to find or create
  # @return [Google::Cloud::PubSub::Subscription]
  def subscription(name)
    client.subscription("#{name}-sub") || self.topic(name).subscribe("#{name}-sub")
  end

  private

  # Create a new client.
  #
  # @return [Google::Cloud::PubSub]
  def client
    @client ||= Google::Cloud::PubSub.new(project_id: "code-challenge")
  end
end
