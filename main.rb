require 'telegram/bot'
require 'nokogiri'
require 'mechanize'

@game = 'dozor_classic'

if @game == 'dozor_classic'
	load 'Dozor_classic.rb'
	bot = Dozor_classic.new
	bot.token = ''
	bot.turn_on
end



