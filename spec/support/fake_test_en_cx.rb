require 'sinatra/base'

class FakeTestEnCx < Sinatra::Base
  DIR = "#{File.dirname(__FILE__)}/fixtures".freeze

  get '/GameCalendar.aspx' do
    content_type 'text/html'
    status = request.params['status'].downcase
    zone = request.params['zone'].downcase
    page = request.params['page'] || 1
    fn = "#{DIR}/test.en.cx_calendar_#{status}_#{zone}_p#{page}.txt"
    File.open(fn)
  end

  get '/GameDetails.aspx' do
    content_type 'text/html'
    fn = "#{DIR}/test.en.cx_game_#{request.params['gid']}.txt"
    File.open(fn)
  end

  get '/UserDetails.aspx' do
    content_type 'text/html'
    fn = "#{DIR}/test.en.cx_player_#{request.params['uid']}.txt"
    File.open(fn)
  end

  get '/Teams/TeamDetails.aspx' do
    content_type 'text/html'
    fn = "#{DIR}/test.en.cx_team_#{request.params['tid']}.txt"
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
    File.open("#{DIR}/test.en.cx_index.txt")
  end
end
