require 'sinatra/activerecord'

configure :production, :development do
	db = URI.parse(ENV['DATABASE_URL'] || 'postgres://localhost/bad-trading-advice')

	ActiveRecord::Base.establish_connection(
			:adapter => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
			:host     => db.host,
			:username => db.user,
			:password => db.password,
			:database => db.path[1..-1],
			:encoding => 'utf8'
	)
end

class Twit < ActiveRecord::Base

	def self.last_ids
		StockTwits::SYMBOLS.keys.each_with_object({}) do |symbol, obj|
      obj[symbol] = Twit.where(stock: symbol).maximum(:key)
    end
	end

	def self.all_twits
		Twit.all.map { |twit| twit.body }
	end
end
