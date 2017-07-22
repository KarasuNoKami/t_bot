class DozorClassic
	include BotApi

	@link
	@prefix
	@auth_data

	@auth_status = false
	@parse_status = false
	@prefix_status = false

	@agent

	def turn_on
		Telegram::Bot::Client.run(TOKEN) do |bot|
			bot.listen do |message|
				@chat_id = message.chat.id
				case message.text
					when /^\/change_game/
						send('code', 'Exit DozoR Classic game')
						return

					when /^\/help/
						send('text', DOZOR_HELP)

					when /^\/auth/
						@auth_data = message.text.split(' ')
						if (!@auth_data[4])
							send('text', 'Enter you login password pin pass')
							break
						end
						send('code', authorization)

					when /^\/(pon|parse_on)/
						@parse_status = true
						send('code', 'parse is on')

					when /^\/(poff|parse_off)/
						@parse_status = false
						send('code', 'parse is off')

					when /^\/prefix_on/
						@prefix = message.text.split(' ')[1]
						@prefix_status = true
						send('code', "prefix #{@prefix} is on")

					when /^\/prefix_off/
						@prefix_status = false
						send('code', "prefix #{@prefix} is off")

					when /\d+\.\d+(\,\s+|\s+)\d+\.\d+/
						send('pre', message.text)
						send('cord', message.text[/\d+\.\d+(\,\s+|\s+)\d+\.\d+/])

					#fun commands below

					when /(Бот|бот) мудак/
						send('sticker', 'img/mudak.png')

					when /\/shrug/
						send('text', "¯\\_(ツ)_/¯") 
				end

				case message.text
					when /^\/fast_link|^\/fl/
						send('text', @auth_data[3] + ':' + @auth_data[4] + '@' + @link.split('//')[1])

					when /(^(\.|#|\?))|(^[DdRrДдРр\d]{3})/
						send('text', send_code(message.text)) if @parse_status

					when /^\/ko/
						send('pre', ko)
				end if @auth_status

			end
		end
	end

	def authorization
		@agent = Mechanize.new
		city = @auth_data[3].split('_')[0]
		@link = "http://classic.dzzzr.ru/#{city}/go"

		begin
			page = @agent.add_auth("#{@link}", @auth_data[3], @auth_data[4])
			page = @agent.get(@link)
		rescue => error
			return 'Authorization failed'
		end

		page = @agent.get(@link)
		logout_button = @agent.page.links.find {|l| l.text == 'выход'}
		logout_button.click if logout_button

		html = Nokogiri::HTML(page.body)
		html.encoding = 'utf-8'
		page_body = html.at_css('body').text.to_s
		return 'Вы не заявлены ни в одной из игр' if page_body.include?('не заявлены')

		form = page.forms.first
		if form
			form.login = @auth_data[1]
			form.password = @auth_data[2]
			@agent.submit(form)
		end
		
		page = get_page
		page_body = page.at_css('body').text.to_s
		
		return 'Failed to load page after authorization' if page_body == nil
		if page_body.include?('успешно') || page_body.include?('найдено кодов') || page_body.include?('Приветствуем участников')
			@auth_status = true
			return 'Authorization success'
		elsif page_body.include?('Авторизуйтесь')
			return 'HTTP authorization success, login failed'
		end
		return 'Something unknown happend'
	end

	def send_code(message)
		(message =~ /^(\.|\?|#)/) == 0 ? message[0] = '' : message = message.downcase.gsub(/[Ддd]/, 'D').gsub(/[Ррr]/, 'R')
		message = @prefix + message if @prefix_status
		page = @agent.get(@link)
		return 'Вам не выдано' if !check_page

		code_form = page.form_with :name => 'codeform'
		return 'cant find form' if code_form == nil

		code_form.field_with(:name=>'cod').value = message
		page = @agent.submit code_form
		page = Nokogiri::HTML(page.body)
		page.encoding = 'utf-8'

		case page.at_css('.sysmsg').text
			when /\sВыполняйте следующее задание./
				return "#{message} Код принят. Новое задание!"

			when /Вы нашли все основные коды/
				return "#{message} Код принят. Вы нашли все основные коды"

			when /ложный код/
				return "#{message} Это ложный код"

			when /Код не принят.\sВы пытаетесь повторно | уже ввели/
				return "#{message} Вы уже ввели этот код"

			when /Принят бонусный код/
				return "#{message} Принят бонусный код"

			when /Код принят/
				return "#{message} Код принят"

			else
				return "#{message} Код не принят"
		end

		return message
	end

	def get_page
		page = @agent.get(@link)
		page = Nokogiri::HTML(page.body)
		page.encoding = 'utf-8'
		page
	end

	def check_page
		page = get_page
		return page.text.include?('Вам не выдано') || page.text.include?('Ждем вас к началу') ? false : true
	end

	def ko
		return 'Вы не на уровне' if !check_page

		page = get_page.to_s
		page[-1..-3] = ''
		page = page
			.split('Коды сложности</strong><br>')[1]
			.split('</div>')[0]
			.gsub('</span>', ' ✔')
			.gsub('<span style="color:red">', '')
			.gsub('<br>', "\n")
			.gsub(' бонус', 'Бонус')
			.gsub(' основн', 'Основн')

		return page
	end

end
