require 'sinatra/base'

class FakeTestEnCx < Sinatra::Base
  get '/GameCalendar.aspx' do
    content_type 'text/html'
    status = request.params['status'].downcase
    dir = File.dirname(__FILE__)
    zone = request.params['zone'].downcase
    page = request.params['page'] || 1
    fn = "#{dir}/fixtures/test.en.cx_calendar_#{status}_#{zone}_p#{page}.html"
    File.open(fn)
  end

  get '/GameDetails.aspx' do
    content_type 'text/html'
    dir = File.dirname(__FILE__)
    fn = "#{dir}/fixtures/test.en.cx_game_#{request.params['gid']}.html"
    File.open(fn)
  end

  post '/login/signin' do
    content_type :json

    res = {
      IpUnblockUrl: nil,
      BruteForceUnblockUrl: nil,
      ConfirmEmailUrl: nil,
      CaptchaUrl: nil,
      AdminWhoCanActivate: nil,
      Message: '',
      Error: 0
    }

    correct = { Login: 'testuser', Password: 'correct' }

    request.body.rewind
    opts = JSON.parse request.body.read

    return res.to_json if opts == correct.collect { |k, v| [k.to_s, v] }.to_h

    res[:Message] = 'Неправильный логин или пароль'
    res[:Error] = 2
    res.to_json
  end

  get '/' do
    dir = File.dirname(__FILE__)
    File.open("#{dir}/fixtures/test.en.cx_index.html")
  end
end
