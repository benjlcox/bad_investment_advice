require 'redis'
require 'sidekiq'
require 'sidekiq/api'

require './lib/stocktwits'

class PostWorker
  include Sidekiq::Worker

  def perform(message)
    return unless message
    StockTwits.post_to_twits(message)
  end

end
