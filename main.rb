require 'json'
require 'nokogiri'
require 'mechanize'
require 'telegram/bot'

load 'modules/bot_api.rb'
load 'bot_modes_classes/Default.rb'
load 'bot_modes_classes/dozor_classic.rb'

bot = Default.new
bot.turn_on
