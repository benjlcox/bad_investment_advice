require 'sinatra'
require './db/db'
require './stocktwits'

get '/' do
  StockTwits.new_sentence
end

get '/last_ids' do
  Twit.last_ids.to_json
end

get '/messages' do
  Twit.all_twits.to_json
end
