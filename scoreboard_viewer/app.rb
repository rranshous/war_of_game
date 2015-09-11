require 'sinatra'
require 'json'


helpers do
  def players tournament
    tournament.map do |(_, (player1, player2), _)|
      [player1.split.last, player2.split.last]
    end.flatten.uniq.sort
  end

  def scores tournament
    wins = [];
    losses = [];
    tournament.map do |(winner, players, _)|
      loser = winner == 0 ? 1 : 0
      if winner
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
    .map{ |l| JSON.load(l.chomp) }
    .map do |d|
      """
      <b>Tournament</b></br>
      <b>Players: </b>#{players(d).join(', ')}<br/>
      <b>Scores: </b>#{scores(d)}<br/>
      <hr/>
      """
    end
    .join("<br/>\n")
end
