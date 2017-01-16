

class PlayerShim

  def initialize to_player, from_player
    @to_player, @from_player = to_player, from_player
  end

  def game_started base_location
    @to_player.puts 'game start'
    @to_player.puts "b #{base_location[0]} #{base_location[1]}"
    @to_player.puts 'game details end'
  end

  def round_started player_warriors, enemy_warriors, dead_warriors, enemy_bases
    @to_player.puts 'round start'
    player_warriors.each do |id, (x, y)|
      @to_player.puts "w #{id} #{x} #{y}"
    end
    enemy_warriors.each do |(player_id, (x, y))|
      @to_player.puts "ew #{player_id} #{x} #{y}"
    end
    dead_warriors.each do |(_, (x, y))|
      @to_player.puts "dw NOTGIVEN #{x} #{y}"
    end
    enemy_bases.each do |player_id, (x, y)|
      @to_player.puts "eb #{player_id} #{x} #{y}"
    end
    @to_player.puts "round details end"
  end

  def die
    @to_player.puts "gameover died"
  end

  def win
    @to_player.puts "gameover win"
  end

  def next_moves
    Enumerator.new do |yielder|
      @from_player.each_line do |line|
        line = line.chomp
        if line == 'done'
          break
        end
        _, id, x, y = line.split.map(&:to_i)
        yielder << [id, [x, y]]
      end
    end
  end
end
