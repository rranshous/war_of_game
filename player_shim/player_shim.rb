

class PlayerShim

  def initialize to_player, from_player
    @to_player, @from_player = to_player, from_player
  end

  # TODO when does player get their bases location ?

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

  # TODO: clear out moves sent in the last round
  # but which were sent after the 1s cutoff
  def next_moves
    Enumerator.new do |yielder|
      @from_player.each_line do |line|
        line = line.chomp
        break if line == 'done'
        _, id, x, y = line.split
        yielder << [id, [x, y]]
      end
    end
  end
end
