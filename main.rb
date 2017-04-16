require 'telegram/bot'
require 'nokogiri'
require 'mechanize'

TOKEN = ''

Telegram::Bot::Client.run(TOKEN) do |bot|
		bot.listen do |message|

			game_bot = 'default' if game_bot == nil

			case message.text

				when /\/game/

					case message.text.split(' ')[1]

						when /dzr/
							bot.api.send_message(
								chat_id: message.chat.id,
								text: 'Я готов для игры в DozoR Classic, капитан'
							)
							load 'Dozor_classic.rb'
							game_bot = Dozor_classic.new
							game_bot.token = TOKEN
							game_bot.turn_on

					end

				when /\/help/
					bot.api.send_message(
								chat_id: message.chat.id,
								text: 'Для выбора игры введите /game "название игры". 
В данный момент доступны: 
DozoR Classic (dzr)

Более подробраную информацию можно получить после выбора игры по команде /help
')

			end
	
	end
end # Конец цикла телеграма
