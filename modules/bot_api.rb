module BotApi
		
	TOKEN = ''.freeze
	DOZOR_HELP = "Я понимаю следующие команды:\n\n"\
    "/parse_on (/pon) - Включить режим парсинга\n"\
    "/parse_off (/poff) - Выключить режим парсинга\n"\
    "/ko - Отправляю в чат ситуацию по кодикам\n"\
    "/prefiks_on \"число\" - Перед вашими кодиками ставлю указанный префикс\n"\
    "/prefiks_off - А теперь не ставлю\n"\
    "/fast_link (/fl) - Отсылаю быструю ссылку на движок\n"\
    "/ko_god_mode_on (/kgmon) - Кодики парсятся с нумерацией\n"\
    "/ko_god_mode_off (/kgmoff) - А теперь нет\n"\
    "/help - Отсылаю этот текст\n"\
    "\nЯ умею принимать кодики как с английскими, так и с русскими буквами.\n"\
    'А еще любые слова с точкой, знаком ? или знаком # в начале буду'\
    " пробиваться в движок независимо от формата.\n"\
    'А еще мне можно присылать координаты формата хх.хххххх, хх.хххххх, как с'\
    ' запятой, так и без, в середине \ начале \ конце текста'\
    "\nБот постоянно развивается. По всем попросам @karasunokami".freeze

	def send(mode, text, html = 'code')
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
        text = text.split(/\s|,\s/)
        bot.api.send_location(
          chat_id: @chat_id,
          latitude: text[0].to_f,
          longitude: text[1].to_f
        )

      when 'html'
        bot.api.send_message(
          chat_id: @chat_id,
          text: "<#{html}>" + text + "</#{html}>",
          parse_mode: 'HTML'
        )
      end
      break
    end
  end
	
end

