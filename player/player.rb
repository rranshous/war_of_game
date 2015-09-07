
class Player

  def initialize name=nil
    @name = name
  end

  # TODO
  def game_started base_location, enemy_base_locations
    @base_location = base_location
    @enemy_base_locations = enemy_base_locations
    puts "player #{@name} base location: #{@base_location}"
    puts "player #{@name} enemy base locations: #{@enemy_base_locations}"
  end

  def round_started player_warriors, enemy_warriors, dead_warriors
    puts "player #{@name} Round Started"
    @current_warriors = player_warriors
    puts "player #{@name} current_warriors: #{@current_warriors}"
    @enemy_warriors = enemy_warriors
    puts "player #{@name} enemy_warriors: #{@enemy_warriors}"
    @dead_warriors = dead_warriors
    puts "player #{@name} dead_warriors: #{dead_warriors}"
    @game_over = false
  end

  def die
    @game_over = :LOSE
    puts "player #{@name} LOST"
  end

  def win
    @game_over = :WIN
    puts "player #{@name} WON"
  end

  def next_moves
    puts "player #{@name} giving moves"
    Enumerator.new do |yielder|
      @current_warriors.each do |(id, (x, y))|
        move = [id, [x+rand(-1..1), y+rand(-1..1)]]
        puts "player #{@name} move: #{move}"
        yielder << move
      end
    end
  end
end

class MoldablePlayer < Player

  MOVES = {
    NORTH: ->(*_){ [0,-1] },
    SOUTH: ->(*_){ [0, 1] },
    EAST:  ->(*_){ [1, 0] },
    WEST:  ->(*_){ [-1, 0] },
    TOWARD_ENEMY_BASE: lambda do |state, toward|
      toward.call state[:enemy_base_locations].first[1]
    end,
    TOWARD_FRIENDLY_BASE: lambda do |state, toward|
      toward.call state[:friendly_base_location]
    end,
    TOWARD_ENEMY_WARRIOR: lambda do |state, toward|
      toward.call state[:enemy_warriors].first[1]
    end,
    TOWARD_FRIENDLY_WARRIOR: lambda do |state, toward|
      toward.call state[:friendly_warriors].first[1]
    end
  }

  def initialize name, move_chances
    @move_chances = move_chances
    raise "wrong # of moves" if @move_chances.length != MOVES.length
    super name
  end

  def next_moves
    puts "player #{@player} giving moves"
    Enumerator.new do |yielder|
      @current_warriors.each do |(id, (x, y))|
        move = [ id, compute_move_from(x, y) ]
        puts "player #{@player} move: #{move}"
        yielder << move
      end
    end
  end

  def compute_move_from x, y
    state = {
      friendly_warriors: @current_warriors,
      enemy_warriors: @enemy_warriors,
      dead_warriors: @dead_warriors,
      friendly_base_location: @base_location,
      enemy_base_locations: @enemy_base_locations
    }
    move_mag = [0, 0]
    MOVES.each_with_index do |(_, get_mag), i|
      if rand(100) < @move_chances[i]
        mag = get_mag.call(state,
                           ->(target_loc){ self.class.toward([x, y], target_loc) })
        unless mag.nil?
          move_mag[0] += mag[0]
          move_mag[1] += mag[1]
        end
      end
    end
    constrain move_mag
    [x+move_mag[0], y+move_mag[1]]
  end

  def constrain mv
    mv[0] = [-1, [1, mv[0]].min].max
    mv[1] = [-1, [1, mv[1]].min].max
  end

  private

  def self.toward start_loc, target_loc
    [0,0].tap do |move|
      if start_loc[0] > target_loc[0]
        move[0] = -1
      elsif start_loc[0] < target_loc[0]
        move[0] = 1
      end
      if start_loc[1] > target_loc[1]
        move[1] = -1
      elsif start_loc[1] < target_loc[1]
        move[1] = 1
      end
    end
  end
end
