require 'sinatra'
require 'json'

set :public_folder, "./game_outputs"

helpers do
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
    .each_slice(2)
    .map{ |gid, json| [gid, JSON.load(json.chomp)] }
    .to_enum.each_with_index.to_a
    .reverse
    .map do |(gid, d), i|
      """
      <b>Tournament #{i}</b></br>
      <b>Players: </b>#{players(d).join(', ')}<br/>
      <a href='/#{gid}.txt'>game output</a><br/><br/>
      <b>Total Wins</b><br/>
      <table cellpadding='2'>
      #{scores(d).to_a.sort_by(&:last).reverse.map{|p,s| "<tr><td>#{s.to_s.ljust(3)}</td><td>#{p}</td></tr>"}.join("\n")}
      </table>
      <b>Game Results: </b><br/>
      <table cellpadding='2'>
      #{games(d).map do |(w, pls, e)|
        if w.nil?
          "<tr><td>#{pls[0]}</td><td><i>vs</i></td><td>#{pls[1]}</td><td><i>no score</i></td><td>#{e}</td></tr>"
        else
          "<tr><td>#{pls[w]}</td><td><i>vs</i></td><td>#{pls[w == 0 ? 1 : 0]}</td><td><i>in</i></td><td>#{e}</td></tr>"
        end
      end.join("\n")}
      </table>
      <hr/>
      """
    end
    .join("<br/>\n")
end

get '/game_outputs' do
end
