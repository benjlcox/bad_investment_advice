require 'redis'
require 'sidekiq'
require 'sidekiq/api'

require './lib/stocktwits'
require './lib/aws'
require './lib/aws'

class PostWorker
  include Sidekiq::Worker

  def perform(message)
    return unless message
    puts "Downloading dictionary..."
    S3.new.download(ENV['DICTIONARY_FILE'])

    sleep(10)

    puts "Processing Dictionary..."
    Markov.generate

    sleep(10)

    puts "Sending Message..."
    StockTwits.post_to_twits(message)
  end

end
