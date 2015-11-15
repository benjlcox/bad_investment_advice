require 'sinatra'
require 'sinatra/activerecord/rake'
require 'dotenv/tasks'

require './lib/stocktwits'
require './db/db'

namespace :twits do
  task :fetch => :dotenv do
    StockTwits.fetch_twits
    StockTwits.generate_markov
  end
end

namespace :dictionary do
  task :download => :dotenv do
    S3.download('dictionary.mmd')
  end
end
