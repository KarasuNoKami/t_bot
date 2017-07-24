class Default
	include BotApi

	@comment_date = 0

	def turn_on
		threads = []

		# game chosing
		threads << Thread.new do
			Telegram::Bot::Client.run(TOKEN) do |bot|
				bot.listen do |message|
					@chat_id = message.chat.id

					case message.text
						when /^\/help/
							send('text', 'For chosing game send /game ...')

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

		# inform me if someone write in dozor vk group that he\she wants to play dozor
		threads << Thread.new do
			loop do
				comment_agent = Mechanize.new
				page = comment_agent.get(
					'https://api.vk.com/method/board.getComments?group_id=13390519&topic_id=22733567&sort=desc'
				)
				page = Nokogiri::HTML(page.body)
				json = JSON.parse(page.text)
				comment = json['response']['comments'][1]
				date = comment['date']

				@chat_id = 211021342
				if date > @comment_date.to_i
					send('text', comment['text'])
					send('text', "https://vk.com/#{comment['from_id']}")
					@comment_date = date
				end

				sleep 10
			end
		end

		threads.each {|thr| thr.join}
	end

end