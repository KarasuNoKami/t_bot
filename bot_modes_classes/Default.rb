class Default
	include BotApi

	def turn_on
		Telegram::Bot::Client.run(TOKEN) do |bot|
			bot.listen do |message|
				@chat_id = message.chat.id

				case message.text
					when /^\/help/
						send('text', 'For chose game send /game ...')

					when /^\/game/
						case
							when /dzr/
								send('code', 'Game DozoR Classic')
								@game = DozorClassic.new
								@game.turn_on
								
						end

					when /\d+\.\d+(\,\s+|\s+)\d+\.\d+/
						send('pre', message.text)
						send('cord', message.text[/\d+\.\d+(\,\s+|\s+)\d+\.\d+/])
				end

			end
		end

	end

end