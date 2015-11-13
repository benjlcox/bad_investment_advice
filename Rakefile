require './stocktwits'

namespace :twits do
  task :fetch do
    StockTwits.fetch_twits
    StockTwits.generate_markov
  end
end
