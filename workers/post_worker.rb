require 'redis'
require 'sidekiq'
require 'sidekiq/api'

require './lib/stocktwits'
require './lib/aws'
require './lib/markov'

class PostWorker
  include Sidekiq::Worker

  def perform(message)
    return unless message
    puts "Downloading dictionary..."
    S3.new.download(ENV['DICTIONARY_FILE'])

    puts "Sending Message..."
    StockTwits.post_to_twits
  end

end
