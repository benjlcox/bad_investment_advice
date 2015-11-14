require 'sinatra'
require 'sinatra/activerecord/rake'
require './stocktwits'
require './db/db'

namespace :twits do
  task :fetch do
    StockTwits.fetch_twits
    StockTwits.generate_markov
  end
end
