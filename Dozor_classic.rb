class Dozor_classic
	attr_accessor :token

	@chat_id = ''
	@auth_data = ''
	@prefiks = ''

	@@agent = Mechanize.new

	@link = ''

	@parse_mode = false
	@type_mode = false
	@auth_status = false
	@prefiks_mode = false
	@hint_status = false
	
	def turn_on
		
		Telegram::Bot::Client.run(@token) do |bot|
			bot.listen do |message|
				
				@chat_id = message.chat.id
				if @type_mode & @auth_status
					if (message.text =~ /(^\.)|(^[DdRrДдРр\d][DdRrДдРр\d][DdRrДдРр\d])/) != nil 
						(send('text', send_code(message.text)))
					else 
						read(message.text)
					end
				else
					read(message.text)
				end
					
				if message.text.include?('/change_game')
					send('text', 'Настройки бота для DozoR Classic выключены. 
Для выбора игры введите /game "название игры". 
В данный момент доступны: 
DozoR Classic (dzr)')
					
					return 'off'
				end

			end
		end # Конец цикла телеграма

	end

	def read(text)
		case text
			when /^\/start/
				@parse_mode = true
				send('sticker', 'img/lodka.png')

			when /^\/stop_baka/
				@chat_id = ''
				@auth_data = ''
				@prefiks = ''
				@parse_mode = false
				@type_mode = false
				@auth_status = false

			when /^\/help/
				send('text', 'Я понимаю следующие команды:

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
')

			when /Бот мудак|бот мудак/
				send('sticker', 'img/mudak.png')

			when /\/shrug/
				send('text', "¯\\_(ツ)_/¯")

			when /\d(\W\s|\s)\d\d\W/
				send('cord', text)

		end

		if @parse_mode
			case text
				when /^\/type_start|^\/tstart/
			 		@type_mode = true
					send('sticker', 'img/type_start.png')
					send('text', 'Но капитан, вы еще не зарегистрированы') if !@auth_status

				when /^\/type_stop|^\/tstop/
					@type_mode = false
					send('sticker', 'img/type_stop.png')

				when /^\/auth_baka/
					if !@auth_status
						@auth_data = text.split(' ')
						result_of_auth = authorization(@auth_data)
						send('text', result_of_auth)
						if result_of_auth == 'Удачно'
							@auth_status = true
						end
					else
						send('text', 'Вы уже зарегестрировались')
					end

				when /^\/logout_baka/
					send('text', logout(@auth_data))

				when /^\/prefiks_on|^\/pon/
					if @prefiks != ''
						if text.split(' ')[1] == nil
							send('text', 'Необходимо указать префикс')
						else
							@prefiks = text.split(' ')[1]
							send('text', "Перед кодиками я буду ставить #{@prefiks}, капитан")
							@prefiks_mode = true
						end
					end

				when /^\/prefiks_off|^\/poff/
					if !@prefiks_mode
						send('text', 'Но он и так выключен, капитан')
					else
						@prefiks_mode = false
						@prefiks == ''
						send('text', 'Режим префикса выключен, капитан')
					end

				when /^\/fast_link|^\/fl/
					@auth_status ? send('text', get_fast_link()) : send('text', 'Я еще не авторизирован на движке')

				when /^\/ko/
					@auth_status ? ko() : send('text', 'Сначала необходимо авторизироваться')
					
			end # конец проверки сообщений в режиме parse_mode

		end

	end

	def authorization(data)

		@auth_data[0] = data[1].split('_')[0] #Город
		@link = "http://classic.dzzzr.ru/#{@auth_data[0]}/go"

		begin
			@page = @@agent.add_auth("#{@link}", data[1], data[2])
		rescue Mechanize::UnauthorizedError => error
			@page = error
			return 'Не удачно'
		end

		@page = @@agent.add_auth("#{@link}", data[1], data[2])

		begin
			@page = @@agent.get("#{@link}")
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

		if !@auth_data

			begin
				@page = @@agent.add_auth(@link, data[1], data[2])
			rescue Mechanize::UnauthorizedError => error
				@page = error
				return 'Не выходится'
			end

			@page = @@agent.add_auth(@link, data[1], data[2])
			
			@page = agent.page.links.find {|l| l.text == 'выход' }.click if @@agent.page != nil

		end

		return 'Я вышел из движка'
		
	end

	def send_code(text)

		if text =~ /^\./
			text[0] = ''
		else
			text = text.tr('Ддd', 'D').tr('Ррr', 'R')
			text = "#{@prefiks}#{text}" if @prefiks_mode
		end
		
		@page = @@agent.get(@link)
		code_form = @page.form_with :name => "codeform"
		
		return 'Не могу найти поле для ввода кода' if code_form == nil

		code_form.field_with(:name=>"cod").value = text 
		result = @@agent.submit code_form
		html = Nokogiri::HTML(result.body)
		html.encoding = 'utf-8'

		case html.at_css('.sysmsg').text

			when /\sВыполняйте следующее задание./
				return "#{text} Код принят. Новое задание!"

			when /Вы нашли все основные коды/
				return "#{text} Код принят. Вы нашли все основные коды"

			when /ложный код/
				return "#{text} Это ложный код"

			when /уже ввели/
				return "#{text} Вы уже ввели этот код"

			when /Код не принят.\sВы пытаетесь повторно/
				return "#{text} Вы уже ввели этот код"

			when /Принят бонусный код/
				return "#{text} Принят бонусный код"

			when /Вы прошли все/
				return "#{text} Код принят. Мы это сделали, капитан"

			when /Код принят/
				return "#{text} Код принят"

			else
				return "#{text} Код не принят"

		end

	end

	def get_fast_link
		"http://#{@auth_data[1]}:#{@auth_data[2]}@classic.dzzzr.ru/#{@auth_data[0]}/go"
	end

	def ko

		html = @@agent.get "http://classic.dzzzr.ru/#{@auth_data[0]}/go"
		html = Nokogiri::HTML(html.body)
		html.encoding = 'utf-8'

		if html.body.to_s.include?('Вам не запланировано')
			send('text', 'Вам не запланировано, капитан')
		else

			ko = html.css('.zad')[0].to_s.split('Коды сложности</strong>')[1].gsub(/<br>/, '
').gsub(/<span style="color:red">|<\/div>/, '').gsub('</span>', '#').gsub('#', ' ✔').gsub('бонусные', 'Бонусные').gsub(' основ', 'Основ').strip
			
			send('code', "<pre>#{ko}</pre>")
			
			hint_text = html.css('body').to_s.split('Последние три события игры команды')[0]
			time = hint_text.split('Время на уровне: ')[1].split(' (на моме')[0]
			if hint_text.include?('Подсказка l')
				send('code', '<b>Первая подсказка выдана!</b>')
				if hint_text.include?('Подсказка 2')
					send('code', '<b>Вторая подсказка выдана!</b>')
				end
			end
			send('text', "Мы на уровне уже #{time}")
		end

	end

	def send(mode, text)

		Telegram::Bot::Client.run(@token) do |bot|
			

			if mode == 'text'
				bot.api.send_message(
					chat_id: @chat_id,
					text: text
				)

			elsif mode == 'sticker'
				bot.api.send_sticker(
					chat_id: @chat_id,
					sticker: Faraday::UploadIO.new(text, 'image/png')
				)

			elsif mode == 'cord'
				text = text.rstrip
				text.include?(', ') ? text = text.split(', ') : text = text.split(' ')
				
				bot.api.send_location(
					chat_id: @chat_id,
					latitude: text[0].to_f,
					longitude: text[1].to_f
				)

			elsif mode == 'code'
				bot.api.send_message(
					chat_id: @chat_id,
					text: text,
					parse_mode: 'HTML'
				)

			end
			
			break 
			
		end # Конец цикла телеграма

	end

end
