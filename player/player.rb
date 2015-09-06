

class Player


  def game_started base_locations
    @base_locations = base_locations
  end

  def round_started player_warriors, enemy_warriors, dead_warriors
    puts "player Round Started"
    @current_warriors = player_warriors
    puts "current_warriors: #{@current_warriors}"
    @enemy_warriors = enemy_warriors
    puts "enemy_warriors: #{@enemy_warriors}"
    @dead_warriors = @dead_warriors
    puts "dead_warriors: #{dead_warriors}"
    @game_over = false
  end

  def die
    @game_over = :LOSE
    puts "player LOST"
  end

  def win
    @game_over = :WIN
    puts "player WON"
  end

  def next_moves
    puts "player giving moves"
    Enumerator.new do |yielder|
      @current_warriors.each do |(id, (x, y))|
        move = [id, [x+rand(-1..1), y+rand(-1..1)]]
        puts "player move: #{move}"
        yielder << move
      end
    end
  end
end
