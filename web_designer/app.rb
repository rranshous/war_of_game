require 'sinatra'
require 'shellwords'
require 'json'
require_relative '../tournament/tournament'

get '/' do
  erb :index
end

get '/run' do
  player0 = params[:player0]
  player1 = params[:player1_genes].split(' ').map(&:to_i).join(' ') # security!
  cmd = ["docker", "run", "-i", "-v", "/var/run/docker.sock:/var/run/docker.sock",
        "rranshous/wog_tournament 100 1",
        "\"docker run -i rranshous/wog_player #{player0}\"",
        "\"docker run -i rranshous/wog_player molded #{player1}\""].join(' ')
  output = []
  puts 'starting'
  puts "CMD: #{cmd}"
  Open3.popen3({},cmd) do |stdin, stdout, stderr, wait_thr|
    stdin.close
    output = stdout.readlines.map(&:chomp).select{ |l| l.length > 0 }
  end
  data = breakup_tournament_log(output)
  frames = breakup_game(data[0])
  r = data[:result_data].first
  content_type :json
  { winner: r[0], rounds: r[2], frames: frames }.to_json
end


helpers do
  def breakup_tournament_log lines
    game_num = 0
    lines.shift
    games = lines.group_by do |l|
      game_num = 'RESULTS' if l['RESULTS'] 
      game_num += 1 if l['tournament_game_starting']
      game_num
    end
    games[:result_data] = JSON.load(games['RESULTS'].last)
    games
  end

  def breakup_game lines
    lines.shift
    frame = 0
    lines
    .reject{ |l| l['WINNER'] }
    .group_by do |l|
      frame += 1 if l['player ']
      frame
    end.values
  end
end
