
class Player

  def initialize name=nil
    @name = name
  end

  # TODO
  def game_started base_location
    @base_location = base_location
  end

  def round_started player_warriors, enemy_warriors, dead_warriors, enemy_bases
    @current_warriors = player_warriors
    @enemy_warriors = enemy_warriors
    @dead_warriors = dead_warriors
    @enemy_base_locations = enemy_bases
    @game_over = false
  end

  def die
    @game_over = :LOSE
  end

  def win
    @game_over = :WIN
  end

  def next_moves
    Enumerator.new do |yielder|
      @current_warriors.each do |(id, (x, y))|
        move = [id, [x+rand(-1..1), y+rand(-1..1)]]
        yielder << move
      end
    end
  end

  private

  def constrain mv
    mv[0] = [-1, [1, mv[0]].min].max
    mv[1] = [-1, [1, mv[1]].min].max
  end

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

# head for base, do not stop at go
class StrikingPlayer < Player
  def next_moves
    if @enemy_base_locations.length > 0
      Enumerator.new do |yielder|
        @current_warriors.each do |(id, (x, y))|
          move_mag = self.class.toward([x,y], @enemy_base_locations.first[1])
          move = [id, [x+move_mag[0], y+move_mag[1]]]
          yielder << move
        end
      end
    else
      super
    end
  end
end

# generally attack
class AttackPlayer < Player
  def next_moves
    if @enemy_warriors.length == 0 && @enemy_base_locations.length == 0
      super
    else
      Enumerator.new do |yielder|
        @current_warriors.each do |(id, (x, y))|
          if @enemy_warriors.length > 0
            target = @enemy_warriors.first[1]
          else
            target = @enemy_base_locations.first[1]
          end
          move_mag = self.class.toward([x,y], target)
          move = [id, [x+move_mag[0], y+move_mag[1]]]
          yielder << move
        end
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
      base = state[:enemy_base_locations].first
      if base
        toward.call base[1]
      else
        [0, 0]
      end
    end,
    TOWARD_FRIENDLY_BASE: lambda do |state, toward|
      toward.call state[:friendly_base_location]
    end,
    TOWARD_ENEMY_WARRIOR: lambda do |state, toward|
      warrior = state[:enemy_warriors].first
      if warrior
        toward.call warrior[1]
      else
        [0, 0]
      end
    end,
    TOWARD_FRIENDLY_WARRIOR: lambda do |state, toward|
      warrior = state[:friendly_warriors].first
      if warrior
        toward.call warrior[1]
      else
        [0, 0]
      end
    end
  }

  def initialize name, move_chances
    @move_chances = move_chances
    raise "wrong # of moves" if @move_chances.length != MOVES.length
    super name
  end

  def next_moves
    Enumerator.new do |yielder|
      @current_warriors.each do |(id, (x, y))|
        move = [ id, compute_move_from(x, y) ]
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

end
