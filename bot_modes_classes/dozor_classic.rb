# telegram bot Dozor Classic game class 
class DozorClassic
  include BotApi

  def initialize
    
    @agent = Mechanize.new
  end

  def turn_on
    Telegram::Bot::Client.run(TOKEN) do |bot|
      bot.listen do |message|
        @chat_id = message.chat.id
        case message.text
        when %r{^/change_game}
          send('html', 'Exit DozoR Classic game')
          return
        end
        process_messages(message)
        process_auth_messages(message) if @auth_status
      end
    end
  end

  def process_messages(message)
    case message.text
    when %r{^/help}
      send('text', DOZOR_HELP)

    when %r{^/auth}
      @auth_data = message.text.split(' ')
      unless (@auth_data[4])
        send('text', 'Enter you login password pin pass')
      else
        send('html', authorization)
      end

    when %r{^(/ko_god_mode_on|/kgmon)}
      @ko_god_mode = true
      send('html', 'ko_god_mode id on HOLY SHIT')

    when %r{^(/ko_god_mode_off|/kgmoff)}
      @ko_god_mode = false
      send('html', 'ko_god_mode id off')

    when %r{^/(pon|parse_on)}
      @parse_status = true
      send('html', 'parse is on')

    when %r{^/(poff|parse_off)}
      @parse_status = false
      send('html', 'parse is off')

    when %r{^/prefix_on}
      @prefix = message.text.split(' ')[1]
      @prefix_status = true
      send('html', "prefix #{@prefix} is on")

    when %r{^/prefix_off}
      @prefix_status = false
      send('html', "prefix #{@prefix} is off")

    when /\d+\.\d+(\,\s+|\s+)\d+\.\d+/
      send('html', message.text, 'pre')
      send('cord', message.text[/\d+\.\d+(\,\s+|\s+)\d+\.\d+/])

    #fun commands below
    when /(Бот|бот) мудак/
      send('sticker', 'img/mudak.png')

    when %r{^/shrug}
      send('text', "¯\\_(ツ)_/¯") 
    end
  end

  def process_auth_messages(message)
    case message.text
    when %r{^/fast_link|/fl}
      send('text', @auth_data[3] + ':' + @auth_data[4] + '@' + @link.split('//')[1])

    when /(^(\.|\?|#))|(^[DdRrДдРр\d]{3})/
      send('text', send_code(message.text)) if @parse_status

    when %r{^/ko}
      ko.is_a?(String) ? send('html', ko) : ko.each { |e| send('html', e, 'pre') }
    end 
  end

  def authorization
    city = @auth_data[3].split('_')[0]
    @link = "http://classic.dzzzr.ru/#{city}/go"

    begin
      page = @agent.add_auth("#{@link}", @auth_data[3], @auth_data[4])
      page = @agent.get(@link)
      page = @agent.get(@link)
      logout_button = @agent.page.links.find {|l| l.text == 'выход'}
      logout_button.click if logout_button
      html = Nokogiri::HTML(page.body)
      html.encoding = 'utf-8'
      page_body = html.at_css('body').text.to_s
    rescue => error
      return 'Authorization failed ' + error
    end
    return 'Вы не заявлены ни в одной из игр' if page_body.include?('не заявлены')

    form = page.forms.first
    if form
      form.login = @auth_data[1]
      form.password = @auth_data[2]
      @agent.submit(form)
    end
    
    page = get_page(@link)
    page_body = page.at_css('body').text.to_s
    return 'Failed to load page after authorization' unless page_body
    process_auth_result(page_body)
  end

  def process_auth_result(result)
    if result.include?('успешно') ||
       result.include?('найдено кодов') ||
       result.include?('Приветствуем участников') 
      @auth_status = true
      return 'Authorization success'
    elsif result.include?('Авторизуйтесь')
      return 'HTTP authorization success, login failed'
    else
      return 'Something unknown happend'
    end
  end

  def send_code(message)
    if /^(\.|\?|#)/.match(message)
      message[0] = ''
    else 
      message = message.downcase.gsub(/[Ддd]/, 'D').gsub(/[Ррr]/, 'R')
      message = @prefix + message if @prefix_status
    end
    
    page = @agent.get(@link)
    return 'Вы не на уровне' unless is_page?

    code_form = page.form_with :name => 'codeform'
    return 'cant find form' unless code_form

    code_form.field_with(:name=>'cod').value = message
    page = @agent.submit code_form
    page = Nokogiri::HTML(page.body)
    page.encoding = 'utf-8'
    result = page.at_css('.sysmsg').text
    return process_send_code_result(message, result) if result
  end

  def process_send_code_result(message, result)
    case result
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
  end

  def is_page?
    page = get_page(@link)
    if page.text.include?('Вам не выдано') || page.text.include?('Ждем вас к на')
      false
    else
      true
    end
  end

  def ko
    return 'Вы не на уровне' unless is_page?
    text = get_page(@link).to_s
      .split('Коды сложности</strong><br>')[1]
      .split('</div>')[0]
      .gsub('</span>', ' √')
      .gsub('<span style="color:red">', '')
      .gsub(' бонус', ' Бонус')
      .gsub(' основн', ' Основн')
    unless @ko_god_mode
      text = text.split('<br>')
    else
      text = numerable_codes(text)
    end
    return text.first text.size - 1 # some ruby magic oO
  end

  def numerable_codes(text)
    text = text.split('<br>').map { |el| 
      el.split('коды: ').each_with_index.map { |el, index|
        if index.odd?
          @ind = 0
          el.split(', ').map { |el| 
            @ind += 1
            el = @ind.to_s + ') ' + el
            el = ' ' + el if @ind < 10 && @ind.odd?
            if @ind.even?
              el = el + "\n"
            elsif @ind < 9
              el = add_space(el, (18 - el.length))
            elsif @ind >= 9 && @ind < 99
              if @ind % 3 == 2
                el = add_space(el, (17 - el.length))
              else
                el = add_space(el, (17 - el.length))
              end
            else
              el = add_space(el, (16 - el.length))
            end
          }
        else
          el
        end
      }.join('')
       .gsub('Основные', "Основные коды\n")
       .gsub('Бонусные', "Бонусные коды\n")
       .gsub(' 1) ', '1) ')
    }
  end

  def add_space(text, num)
    num.times { text += ' '}
    text
  end
end
