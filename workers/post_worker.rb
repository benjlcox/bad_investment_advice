require 'redis'
require 'sidekiq'
require 'sidekiq/api'

require './lib/stocktwits'
require './lib/aws'

class PostWorker
  include Sidekiq::Worker

  def perform(message)
    return unless message
    S3.new.download(ENV['DICTIONARY_FILE'])
    Markov.generate
    StockTwits.post_to_twits(message)
  end

end
