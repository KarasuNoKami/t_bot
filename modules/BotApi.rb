module BotApi
		
	TOKEN = ''
	@chat_id = 0
	@game
	DOZOR_HELP = 'Я понимаю следующие команды:

/start - Поехали
/type_start (/tstart) - Начинаю слушать Ваши кодики
/type_stop (/ttop) - Делаю вид, что ничего не слышу
/ko - Отправляю в чат ситуацию по кодикам, факт наличия подсказок, если таковые уже выпали b текущее время на уровне
/prefiks_on (/pon) "число" - Перед вашими кодиками ставлю указанный префикс
/prefiks_off (/pof) - А теперь не ставлю
/fast_link (/fl) - Отсылаю быструю ссылку на движок
/help - Отсылаю этот текст

Я умею принимать кодики как с английскими, так и с русскими буквами.
А еще любые слова с точкой в начале буду пробиваться в движок независимо от формата.
А еще мне можно присылать координаты формата хх.хххххх, хх.хххххх, как с запятой, так и без.

Бот постоянно развивается. По всем попросам @karasunokami
'

	def send(mode, text)
		Telegram::Bot::Client.run(TOKEN) do |bot|
			case mode
				when 'text'
					bot.api.send_message(
						chat_id: @chat_id,
						text: text
					)

				when 'sticker'
					bot.api.send_sticker(
						chat_id: @chat_id,
						sticker: Faraday::UploadIO.new(text, 'image/png')
					)

				when 'cord'
					text.rstrip!
					text.include?(', ') ? text = text.split(', ') : text = text.split(' ')
					bot.api.send_location(
						chat_id: @chat_id,
						latitude: text[0].to_f,
						longitude: text[1].to_f
					)

				when 'pre'
					bot.api.send_message(
						chat_id: @chat_id,
						text: '<pre>' + text + '</pre>',
						parse_mode: 'HTML'
					)

				when 'code'
					bot.api.send_message(
						chat_id: @chat_id,
						text: '<code>' + text + '</code>',
						parse_mode: 'HTML'
					)
			end
			break 
		end # Конец цикла телеграма
	end
	
end

