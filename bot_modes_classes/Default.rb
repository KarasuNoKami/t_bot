class Default
	include BotApi

	def turn_on
		threads = []

		# game chosing
		threads << Thread.new do
			Telegram::Bot::Client.run(TOKEN) do |bot|
				bot.listen do |message|
					@chat_id = message.chat.id

					case message.text
						when %r{^/help}
							send('text', 'For chosing game send /game ...')

						when %r{^/game}
							case
								when /dzr/
									send('html', 'Game DozoR Classic')
									@game = DozorClassic.new
									@game.turn_on
									
							end

						when /\d+\.\d+(\,\s+|\s+)\d+\.\d+/
							send('html', message.text, 'pre')
							send('cord', message.text[/\d+\.\d+(\,\s+|\s+)\d+\.\d+/])
					end

				end
			end

		end

		# inform me if someone write in dozor vk group that he\she wants to play dozor
		threads << Thread.new do
			puts @comment_date
			loop do
				comment_agent = Mechanize.new
				page = comment_agent.get(
					'https://api.vk.com/method/board.getComments?group_id=13390519&topic_id=22733567&sort=desc&count=5'
				)
				page = Nokogiri::HTML(page.body)
				json = JSON.parse(page.text)
				comments = json['response']['comments']
				
				comments.reverse_each do |comment|
					comment.is_a?(Hash) ? date = comment['date'] : next
					@chat_id = 211021342
					if date > @comment_date.to_i
						send('text', comment['text'])
						send('text', "https://vk.com/id#{comment['from_id']}")
						@comment_date = date
					end
				end
				

				sleep 10
			end
		end

		threads.each {|thr| thr.join}
	end

end