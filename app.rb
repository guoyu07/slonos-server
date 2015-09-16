$:.push(File.expand_path('../lib', __FILE__))

require 'sinatra'
require 'slonos'
require 'pusher'

helpers do
  def spotify
    Spotify::Client.new({
      :raise_errors => true,

      # Connection properties
      :retries       => 0,
    })
  end

  def pusher
    Pusher::Client.new({
      app_id: ENV['PUSHER_APP_ID'],
      key: ENV['PUSHER_APP_KEY'],
      secret: ENV['PUSHER_APP_SECRET'],
    })
  end
end

get '/' do
  "Sonos controller\n"
end

post '/slack_in' do
  req = Slonos::SlackRequest.new(request.body.read)

  match = /!music ([^ ]+) ?(.*)?/.match(req.message)

  return 'Unrecognised command (does not start with !music)' unless match

  subcommand = match[1]
  case subcommand
  when 'play'
    pusher.trigger('commands', 'play', {})
  when 'pause'
    pusher.trigger('commands', 'pause', {})
  when 'add'
    term = match[2]
    return 'No search term!' unless term

    results = spotify.search(:track, term)

    return 'Sorry, nothing found' unless results['tracks']

    pusher.trigger(
      'commands',
      'add',
      {
        id: results['tracks']['items'][0]['id'],
        name: results['tracks']['items'][0]['name']
      }
    )
  else
    return "Unrecognised subcommand '#{subcommand}'"
  end
end