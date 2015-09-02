

class PlayerShim

  def initialize to_player, from_player
    @to_player, @from_player = to_player, from_player
  end

  def announce_round player_warriors, enemy_warriors, enemy_bases, dead_warriors
    @to_player.puts 'start round'
    player_warriors.each do |id, (x, y)|
      @to_player.puts "w #{id} #{x} #{y}"
    end
    enemy_warriors.each do |(player_id, (x, y))|
      @to_player.puts "ew #{player_id} #{x} #{y}"
    end
    enemy_bases.each do |player_id, (x, y)|
      @to_player.puts "eb #{player_id} #{x} #{y}"
    end
    dead_warriors.each do |(player_id, (x, y))|
      @to_player.puts "dw #{player_id} #{x} #{y}"
    end
  end

  def die
    @to_player.puts "died"
  end

  def next_moves
    Enumerator.new do |yielder|
      @from_player.each_line do |line|
        line = line.chomp
        break if line == 'done'
        _, id, x, y = line.split
        yielder << [id, x, y]
      end
    end
  end
end
