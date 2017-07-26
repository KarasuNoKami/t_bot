require 'telegram/bot'
require 'nokogiri'
require 'mechanize'
require 'json'

load 'modules/BotApi.rb'
load 'bot_modes_classes/Default.rb'
load 'bot_modes_classes/DozorClassic.rb'

bot = Default.new
bot.turn_on
