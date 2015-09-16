require 'sinatra'
require 'json'

helpers do

  def games_played_per_player d
    p = d.first[1][0]
    @games_played_per_player ||= d.count{ |(_, players, _)| players.include?(p) }
  end

  def players tournament
    tournament.map do |(_, (player1, player2), _)|
      [player1.split.last, player2.split.last]
    end.flatten.uniq.sort
  end

  def games tournament
    [].tap do |r|
      tournament.map do |(winner, players, conclusion)|
        r << [winner, players.map{|p| p.split.last}, conclusion]
      end
    end
  end

  def scores tournament
    wins = []
    losses = []
    tournament.map do |(winner, players, _)|
      unless winner.nil?
        loser = winner == 0 ? 1 : 0
        wins << players[winner].split.last
        losses << players[loser].split.last
      end
    end
    {}.tap do |r|
      players(tournament).each do |player|
        r[player] = wins.count{ |p| p == player }
      end
    end
  end
end

get '/' do
  File.open('./tournament_results.txt') { |fh| fh.readlines }
    .map{ |l| l.chomp }
    .select{ |l| l.length > 0 }
    .each_slice(2)
    .map{ |gid, json| [gid, JSON.load(json.chomp)] }
    .to_enum.each_with_index.to_a
    .reverse
    .map do |(gid, d), i|
      """
      <b>Tournament #{i}</b></br>
      <b>Players: </b>#{players(d).join(', ')}<br/>
      <a href='/game_outputs/#{gid}.txt'>game output</a><br/><br/>
      <b>Total Wins</b><br/>
      <table cellpadding='2'>
      #{scores(d).to_a.sort_by(&:last).reverse.map{|p,s| "<tr><td>#{s.to_s.ljust(3)}</td><td>#{(s.to_f / games_played_per_player(d) * 100).to_i}%</td><td>#{p}</td></tr>"}.join("\n")}
      <hr/>
      """
    end
    .join("<br/>\n")
end

get '/game_outputs/:id.txt' do |gid|
  headers['Content-Encoding'] = 'gzip'
  content_type :text
  send_file "./game_outputs/#{gid}.gzip"
end
