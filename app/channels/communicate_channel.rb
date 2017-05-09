class CommunicateChannel < ApplicationCable::Channel
  def subscribed
    stream_from "a"
    Rails.logger.info('subscribed')
  end

  def unsubscribed
    Rails.logger.info('unsubscribed')
    # Any cleanup needed when channel is unsubscribed
  end

  def status
    Rails.logger.info('status')
  end
end
