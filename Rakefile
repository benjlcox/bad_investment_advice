require 'sinatra'
require 'sinatra/activerecord/rake'
require 'dotenv/tasks'

require './lib/stocktwits'
require './lib/markov'
require './db/db'

namespace :twits do
  task :fetch => :dotenv do
    StockTwits.new.fetch_twits
  end

  task :post => :dotenv do
    StockTwits.new.post_message
  end
end

namespace :markov do
  task :generate => :dotenv do
    Markov.generate
  end
end

namespace :dictionary do
  task :download => :dotenv do
    S3.new.download(ENV['DICTIONARY_FILE'])
  end
end
