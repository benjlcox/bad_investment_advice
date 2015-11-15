require 'sinatra'
require 'sinatra/activerecord/rake'
require 'dotenv/tasks'

require './lib/stocktwits'
require './lib/markov'
require './db/db'

namespace :twits do
  task :fetch => :dotenv do
    StockTwits.fetch_twits
    Markov.generate
  end
end

namespace :dictionary do
  task :download => :dotenv do
    S3.new.download(ENV['DICTIONARY'])
  end
end
