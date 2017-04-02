class Dozor_classic
	attr_accessor :token

	@@chat_id = ''
	@@auth_data = ''
	@@prefiks = ''

	@@agent = Mechanize.new
	@@link = ''

	@@parse_mode = false
	@@type_mode = false
	@@auth_status = false
	@@prefiks_mode = false
	@@hint_status = false
	
	def turn_on
		
		Telegram::Bot::Client.run(@token) do |bot|
			bot.listen do |message|

				if @@parse_mode & @@type_mode & @@auth_status & check_code(message.text)
					@@chat_id = message.chat.id
					send('text', send_code(message.text))
				else
					@@chat_id = message.chat.id
					text = read(message.text)
				end

			end
		end # Конец цикла телеграма

	end

	def read(text)

		if text.include?('/start')
			@@parse_mode = true
			send('sticker', 'img/lodka.png')
		elsif text.include?('/stop_baka')
			@@chat_id = ''
			@@auth_data = ''
			@@prefiks = ''
			@@parse_mode = false
			@@type_mode = false
			@@auth_status = false
		end

		if @@parse_mode

			if text.include?('/type_start') || text.include?('/tstart')
				@@type_mode = true
				send('sticker', 'img/type_start.png')
				if !@@auth_status
					send('text', 'Но капитан, вы еще не зарегистрированы')
				end
			
			elsif text.include?('/type_stop') || text.include?('/tstop')
				@@type_mode = false
				send('sticker', 'img/type_stop.png')

			elsif text.include?('/auth_baka')
				if !@@auth_status
					@@auth_data = text.split(' ')
					result_of_auth = authorization(@@auth_data)
					send('text', result_of_auth)
					if result_of_auth == 'Удачно'
						@@auth_status = true
					end
				else
					send('text', 'Вы уже зарегестрировались')
				end

			elsif text.include?('/logout_baka')
				send('text', logout())

			elsif text.include?('/prefiks_on') || text.include?('/pon')
				@@prefiks_mode = true
				if @@prefiks == ''
					if text.split(' ')[1] == nil
						send('text', 'Необходимо указать префикс')
					else
						@@prefiks = text.split(' ')[1]
						send('text', "Перед кодиками я буду ставить #{@@prefiks}, капитан")
					end
				end

			elsif text.include?('/prefiks_off') || text.include?('/poff')
				@@prefiks_mode = false
				@@prefiks == ''
				send('text', 'Режим префикса выключен, капитан')

			elsif text.include?('/fast_link') || text.include?('/fl')
				if @@auth_status
					send('text', get_fast_link())
				else
					send('text', 'Я еще не авторизирован на движке')
				end

			elsif text.include?('/status') || text.include?('/ko')
				if @@auth_status
					status()
				else
					send('text', 'Сначала необходимо авторизироваться')
				end

			end
		end # конец проверки сообщений в режиме parse_mode

		if text.include?('/help')
			send('text', 'Я понимаю следующие команды:

/start - Поехали
/type_start (/tstart) - Начинаю слушать Ваши кодики
/type_stop (/ttop) - Делаю вид, что ничего не слышу
/status (/ko) - Отправляю в чат ситуацию по кодикам и факт наличия подсказок, если таковые уже выпали
/prefiks_on (/pon) "число" - Перед вашими кодиками ставлю указанный префикс
/prefiks_off (/pof) - А теперь не ставлю
/fast_link (/fl) - Отсылаю быструю ссылку на движок
/help - Отсылаю этот текст

Я умею принимать кодики как с английскими, так и с русскими буквами.
А еще любые слова с точкой в начале буду пробиваться в движок независимо от формата.
А еще мне можно присылать координаты формата хх.хххххх, хх.хххххх, как с запятой, так и без.

Бот постоянно развивается. По всем попросам @karasunokami
')

		elsif text.include?('Бот мудак')
			send('sticker', 'img/mudak.png')

		elsif text.include?('/shrug')
			send('text', "¯\\_(ツ)_/¯")

		elsif (text.include?('46.') || text.include?('47.') || text.include?('48.') || text.include?('49.') || text.include?('50.')) & (text.include?(' ')  || text.include?(', '))
			send('cord', text)

		end

	end

	def send(mode, text)

		Telegram::Bot::Client.run(@token) do |bot|
			bot.listen do |message|

				if mode == 'text'
					bot.api.send_message(
						chat_id: @@chat_id,
						text: text
					)

				elsif mode == 'sticker'
					bot.api.send_sticker(
						chat_id: @@chat_id,
						sticker: Faraday::UploadIO.new(text, 'image/png')
					)

				elsif mode == 'cord'
					text = text.rstrip
					if text.include?(', ')
						text = text.split(', ')
					else
						text = text.split(' ')
					end
					bot.api.send_location(
						chat_id: message.chat.id,
						latitude: text[0].to_f,
						longitude: text[1].to_f
					)

				elsif mode == 'code'
					bot.api.send_message(
						chat_id: @@chat_id,
						text: text,
						parse_mode: 'HTML'
					)

				end
					
				break 
			end
		end # Конец цикла телеграма

	end

	def authorization(data)

		@@auth_data[0] = data[1].split('_')[0] #Город
		@@link = "http://classic.dzzzr.ru/#{@@auth_data[0]}/go"

		begin
			@page = @@agent.add_auth("#{@@link}", data[1], data[2])
		rescue Mechanize::UnauthorizedError => error
			@page = error
			return 'Не удачно'
		end

		@page = @@agent.add_auth("#{@@link}", data[1], data[2])

		begin
			@page = @@agent.get("#{@@link}")
		rescue Mechanize::UnauthorizedError => error
			@page = error
			logout(data)
			return 'Не удачно'
		end

		

		
		form = @page.forms.first

		form.login = data[3]
		form.password = data[4]

		result = @@agent.submit form

		html = Nokogiri::HTML(result.body)
		html.encoding = 'utf-8'

		if html.at_css('.sysmsg') != nil
			if html.at_css('.sysmsg').text.include?('успешно')
				return 'Удачно'
			elsif html.at_css('.sysmsg').text.include?('Движок остановлен')
				return 'Удачно. Движок остановлен организатором'
			else
				return 'Не удачно'
			end
		else
			return 'Не удачно'
		end

	end

	def logout(data)
		if !@@auth_data
			begin
				@page = @@agent.add_auth(@@link, data[1], data[2])
			rescue Mechanize::UnauthorizedError => error
				 @page = error
				 return 'Не выходится'
			end

			@page = @@agent.add_auth(@@link, data[1], data[2])
			if @@agent.page != nil
				@page = agent.page.links.find {|l| l.text == 'выход' }.click
			end
		end
		return 'Я вышел из движка'
		
	end

	def check_code(text)
		if text[0] == '.'
			return true
		elsif ((/[DdRrДдРр0-9]/ =~ text[0]) == 0) &
					((/[DdRrДдРр0-9]/ =~ text[1]) == 0) &
					((/[DdRrДдРр0-9]/ =~ text[2]) == 0)
			return true
		else
			return false
		end

	end

	def send_code(text)

		if text[0] == '.'
			text = text.delete '.'
		else
			text = text.tr('Дд', 'D')
			text = text.tr('Рр', 'R')
		end

		if @@prefiks_mode
			text = "#{@@prefiks}#{text}"
		end

		# Проверка на наличие задания

		html = @@agent.get "http://classic.dzzzr.ru/#{@@auth_data[0]}/go"
		html = Nokogiri::HTML(html.body)
		html.encoding = 'utf-8'
		if html.at_css('body').text.include?('Вам не запланировано')
			return 'Вам не запланировано, капитан'
		elsif html.at_css('body').text.include?('Вы прошли все основные уровни.')
			return 'Вы прошли все основные уровни, капитан'
		end

		@page = @@agent.get(@@link)

		code_form = @page.form_with :name => "codeform"
		if code_form == nil
			return 'Что-то не так, капитан'
		end

		code_form.field_with(:name=>"cod").value = text
		result = @@agent.submit code_form
		html = Nokogiri::HTML(result.body)
		html.encoding = 'utf-8'

		if html.at_css('.sysmsg').text.include?(' Выполняйте следующее задание.')
			return "#{text} Код принят. Новое задание!"
		elsif html.at_css('.sysmsg').text.include?('Вам не запланировано')
			return "#{text} Код принят. Задание закрыто #ВладзвониДане"
		elsif html.at_css('.sysmsg').text.include?('Вы нашли все основные коды')
			return "#{text} Код принят. Вы нашли все основные коды"
		elsif html.at_css('.sysmsg').text.include?('ложный код')
			return "#{text} Это ложный код"
		elsif html.at_css('.sysmsg').text.include?('уже ввели')
			return "#{text} Вы уже ввели этот код"
		elsif html.at_css('.sysmsg').text.include?('Код не принят. Вы пытаетесь повторно')
			return "#{text} Вы уже ввели этот код"
		elsif html.at_css('.sysmsg').text.include?('Принят бонусный код')
			return "#{text} Принят бонусный код"
		elsif html.at_css('.sysmsg').text.include?('Код принят')
			return "#{text} Код принят"
		elsif html.at_css('body').text.include?('Игра закончена')
			return "#{text} Код принят. Мы это сделали, капитан"
		else
			return "#{text} Код не принят"
		end

	end

	def get_fast_link
		return "http://#{@@auth_data[1]}:#{@@auth_data[2]}@classic.dzzzr.ru/#{@@auth_data[0]}/go"
	end

	def status

		html = @@agent.get "http://classic.dzzzr.ru/#{@@auth_data[0]}/go"
		html = Nokogiri::HTML(html.body)
		html.encoding = 'utf-8'

		ko = html.css('.zad')[0].to_s.split('Коды сложности</strong>')[1].gsub('</div>', '').gsub('</span>', '').to_s
		ko[0] = '>'
		ko = ko.gsub('<span style="color:red">', '#').gsub('<br> ', '
').gsub('>br> ', '').gsub('основ', 'Основ').gsub('бонус', 'Бонус').gsub('<br>', '')
		ko = ko.gsub('#1+', '1+ ✔').gsub('#2+', '2+ ✔').gsub('#3+', '3+ ✔').gsub('#nul', 'nul ✔')
		ko = ko.gsub('#1', '1  ✔').gsub('#2', '2  ✔').gsub('#3', '3  ✔')
		ko = ko.gsub(': ', '
').gsub(', ', '
')

		
		send('code', "<pre>#{ko}</pre>")
		if html.css('body').to_s.split('Последние три события игры команды')[0].include?('Подсказка l')
			send('code', '<b>Первая подсказка выдана!</b>')
		end
		if html.css('body').to_s.split('Последние три события игры команды')[0].include?('Подсказка 2')
			send('code', '<b>Вторая подсказка выдана!</b>')
		end

	end



end