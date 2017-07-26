class DozorClassic
	include BotApi

	@link
	@prefix
	@auth_data
	@ind = 0

	@auth_status = false
	@parse_status = false
	@prefix_status = false
	@ko_god_mode = false

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

					when /^(\/ko_god_mode_on|\/kgmon)/
						@ko_god_mode = true
						send('code', 'ko_god_mode id on HOLY SHIT')

					when /^(\/ko_god_mode_off|\/kgmoff)/
						@ko_god_mode = false
						send('code', 'ko_god_mode id off')

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
					when /^\/fast_link|^\/fs/
						send('text', @auth_data[3] + ':' + @auth_data[4] + '@' + @link.split('//')[1])

					when /(^\.)|(^[DdRrДдРр\d]{3})/
						send('text', send_code(message.text)) if @parse_status

					when /^\/ko/
						send('pre', ko) if !@ko_god_mode
						send('kogm', ko) if @ko_god_mode
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
		if (message =~ /^(\.|\?|#)/) == 0  
			message[0] = ''
		else 
			message = message.downcase.gsub(/[Ддd]/, 'D').gsub(/[Ррr]/, 'R')
			message = @prefix + message if @prefix_status
		end
		
		page = @agent.get(@link)
		return 'Вы не на уровне' if !check_page

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
		if !@ko_god_mode
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
		else
			return 'Вы не на уровне' if !check_page
			page = get_page.to_s
			page[-1..-3] = ''
			codes = page
				.split('Коды сложности</strong><br>')[1]
				.split('</div>')[0]
				.gsub('<span style="color:red">', '')
				.gsub(',', '')
				.split('<br>').map {|el|
					@ind = 0
					el.split(': ').map {|el|
						if (/^\d/ =~ el) == 0
							el.split(' ').map {|el|
								@ind += 1
								el = el.gsub('</span>', ' √')
								el = @ind.to_s + ') ' + el 
								if @ind % 2 == 0
									@el = el + " \n"
								else
									@el = el
									if @ind < 9
										(18 - el.length).times {|el| @el = @el + ' '}
									elsif @ind >= 9 && @ind < 99
										if @ind % 3 == 2
											(17 - el.length).times {|el| @el = @el + ' '}
										else
											(17 - el.length).times {|el| @el = @el + ' '}
										end
									else
										(16 - el.length).times {|el| @el = @el + ' '}
									end
								end
								@el						
							}
						else
							el
						end
					}.join("").gsub(/основн/, "Основн")
										.gsub(/бонусн/, "Бонусн")
										.gsub(/коды/, "коды\n")
				}
			return codes.first codes.size - 1 # some ruby magic oO
		end
	end

end
