require 'telegram/bot'
require 'nokogiri'
require 'mechanize'
require 'json'

load 'modules/bot_api.rb'
load 'bot_modes_classes/default.rb'
load 'bot_modes_classes/dozor_classic.rb'

bot = Default.new
bot.turn_on
