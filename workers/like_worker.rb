require 'redis'
require 'sidekiq'
require 'sidekiq/api'

require './lib/stocktwits'
require './lib/aws'
require './lib/markov'

class LikeWorker
  include Sidekiq::Worker

  def perform(id)
    puts "Sending like for #{id}"
    StockTwits.new.post_like(id)
  end
end
