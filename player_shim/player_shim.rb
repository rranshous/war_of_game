

class PlayerShim

  def initialize to_player, from_player
    @to_player, @from_player = to_player, from_player
  end

  def game_started base_location, enemy_base_locations
    @to_player.puts 'game start'
    @to_player.puts "b #{base_location[0]} #{base_location[1]}"
    enemy_base_locations.each do |pid, (x, y)|
      @to_player.puts "eb #{pid} #{x} #{y}"
    end
    @to_player.puts 'game details end'
  end

  def round_started player_warriors, enemy_warriors, dead_warriors
    @to_player.puts 'round start'
    player_warriors.each do |id, (x, y)|
      @to_player.puts "w #{id} #{x} #{y}"
    end
    enemy_warriors.each do |(player_id, (x, y))|
      @to_player.puts "ew #{player_id} #{x} #{y}"
    end
    dead_warriors.each do |(player_id, (x, y))|
      @to_player.puts "dw #{player_id} #{x} #{y}"
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
        _, id, x, y = line.split
        x, y = [x, y].map(&:to_i)
        yielder << [id, [x, y]]
      end
    end
  end
end
