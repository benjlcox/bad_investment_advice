require 'sinatra'
require './db/db'
require './lib/stocktwits'

get '/' do
  StockTwits.new_sentence
end

get '/last_ids.json' do
  Twit.last_ids.to_json
end

get '/messages.json' do
  Twit.all_twits.to_json
end
