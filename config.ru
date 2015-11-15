require './bad_trading_advice'
require 'dotenv'

Dotenv.load
S3.download('dictionary.mmd')
run Sinatra::Application
