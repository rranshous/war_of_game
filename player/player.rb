class Player

  def initialize name=nil
    @name = name
  end

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
      @current_warriors.each do |(id, _)|
        move = [id, [rand(-1..1), rand(-1..1)]]
        yielder << move
      end
    end
  end

  private

  def constrain mv
    mv[0] = [-1, [1, mv[0]].min].max
    mv[1] = [-1, [1, mv[1]].min].max
  end

  def self.dist loc, wloc
    dx, dy = [ wloc[0] - loc[0], wloc[1] - loc[1] ]
    Math.sqrt(dx*dx + dy*dy)
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

  def self.away_from start_loc, target_loc
    toward(start_loc, target_loc).map{ |m| m * -1 }
  end
end

class RandomPlayer < Player
end

# head for base, do not stop at go
class StrikingPlayer < Player
  def initialize *args
    @explored_territory = {}
    @warrior_targets = {}
    @last_position = {}
    super
  end
  def next_moves
    Enumerator.new do |yielder|
      @current_warriors.each do |(id, (x, y))|
        if @warrior_targets[id] == [x, y] ||
           @warrior_targets[id].nil? ||
           @last_position[id] == [x, y]
          begin
            # inf loop?
            @warrior_targets[id] = [rand(-10..10)+x, rand(-10..10)+y]
          end until @explored_territory[@warrior_targets[id]].nil?
        end
        if @enemy_base_locations.length > 0
          move_mag = self.class.toward([x,y], @enemy_base_locations.first[1])
          move = [id, [move_mag[0], move_mag[1]]]
          @explored_territory[[x+move_mag[0], y+move_mag[1]]] = true
          yielder << move
        else
          move_mag = self.class.toward([x, y], @warrior_targets[id])
          yielder << [id, move_mag]
        end
        @last_position[id] = [x, y]
      end
    end
  end
end

# generally attack
class AttackPlayer < Player
  def initialize *args
    @occupied_spaces = {}
    super
  end
  def next_moves
    if @enemy_warriors.length == 0 && @enemy_base_locations.length == 0
      super
    else
      Enumerator.new do |yielder|
        @current_warriors.each do |(id, (x, y))|
          enemy_warriors = @enemy_warriors.sort_by do |pid, (ex, ey)|
            dx, dy = [ ex - x, ey - y ]
            dist = Math.sqrt(dx*dx + dy*dy)
            dist
          end
          if @enemy_warriors.length > 0
            target = enemy_warriors.first[1]
          else
            target = @enemy_base_locations.first[1]
          end
          move_mag = self.class.toward([x,y], target)
          move = [id, move_mag]
          yielder << move
        end
      end
    end
  end
end

# Try not to kill your team mates
class CarefulPlayer < Player
  def next_moves
    occupied_spaces = Hash[(@current_players || []).map{ |(wid, loc)| [loc, wid] }]
    Enumerator.new do |yielder|
      super.each do |(wid, (x, y))|
        if occupied_spaces[[x,y]].nil?
          occupied_spaces[[x,y]] = wid
          yielder << [wid, [x, y]]
        end
      end
    end
  end
end


class BouncerPlayer < Player

  def initialize *args
    @last_blocked = {}
    @intended_locations = {}
    super
  end

  def round_started *args
    super
    check_for_walls
  end

  def check_for_walls
    @current_warriors.each do |(wid, loc)|
      if @intended_locations[wid].nil?
        @last_blocked[wid] = @base_location.map{ |o| o+rand(-1..1) }
      elsif @intended_locations[wid] != loc
        @last_blocked[wid] = loc.map{ |o| o+rand(-1..1) }
      end
    end
  end

  def next_moves
    Enumerator.new do |yielder|
      @current_warriors.each do |(wid, (x, y))|
        move_mag = self.class.away_from [x, y], @last_blocked[wid]
        @intended_locations[wid] = [x+move_mag[0], y+move_mag[1]]
        yielder << [wid, move_mag]
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
    TOWARD_ENEMY_BASE: lambda do |state, toward, away_from|
      base = state[:enemy_base_locations].first
      if base
        toward.call base[1]
      else
        [0, 0]
      end
    end,
    TOWARD_FRIENDLY_BASE: lambda do |state, toward, away_from|
      toward.call state[:friendly_base_location]
    end,
    TOWARD_ENEMY_WARRIOR: lambda do |state, toward, away_from|
      loc = state[:loc]
      warriors = state[:friendly_warriors]
        .reject{|wid, _| wid == state[:wid]}
        .sort_by do |wid, wloc|
          dx, dy = [ wloc[0] - loc[0], wloc[1] - loc[1] ]
          dist = Math.sqrt(dx*dx + dy*dy)
          dist
        end
      if warriors.length > 0
        toward.call warriors.first[1]
      else
        [0, 0]
      end
    end,
    TOWARD_FRIENDLY_WARRIOR: lambda do |state, toward, away_from|
      loc = state[:loc]
      warriors = state[:enemy_warriors]
        .sort_by do |_, wloc|
          dx, dy = [ wloc[0] - loc[0], wloc[1] - loc[1] ]
          dist = Math.sqrt(dx*dx + dy*dy)
          dist
        end
      if warriors.length > 0
        toward.call warriors.first[1]
      else
        [0, 0]
      end
    end,
    AWAY_FROM_FRIENDLY_WARRIOR: lambda do |state, toward, away_from|
      loc = state[:loc]
      warriors = state[:friendly_warriors]
        .reject{|wid, _| wid == state[:wid]}
        .sort_by do |wid, wloc|
          dx, dy = [ wloc[0] - loc[0], wloc[1] - loc[1] ]
          dist = Math.sqrt(dx*dx + dy*dy)
          dist
        end
      if warriors.length > 0
        away_from.call warriors.first[1]
      else
        [0, 0]
      end
    end,
    AWAY_FROM_ENEMY_WARRIOR: lambda do |state, toward, away_from|
      loc = state[:loc]
      warriors = state[:enemy_warriors]
        .sort_by do |_, wloc|
          dx, dy = [ wloc[0] - loc[0], wloc[1] - loc[1] ]
          dist = Math.sqrt(dx*dx + dy*dy)
          dist
        end
      if warriors.length > 0
        away_from.call warriors.first[1]
      else
        [0, 0]
      end
    end,
    TOWARD_DEATH: lambda do |state, toward, away_from|
      dead_warriors = state[:dead_warriors].sort_by do |(_, dloc)|
        Player.dist state[:loc], dloc
      end
      if dead_warriors.length > 0
        toward.call dead_warriors.first[1]
      else
        [0, 0]
      end
    end,
    AWAY_FROM_DEATH: lambda do |state, toward, away_from|
      dead_warriors = state[:dead_warriors].sort_by do |(_, dloc)|
        Player.dist state[:loc], dloc
      end
      dead_warriors.reverse
      if dead_warriors.length > 0
        toward.call dead_warriors.first[1]
      else
        [0, 0]
      end
    end
  }

  def initialize name, move_chances
    @move_chances = move_chances
    super name
  end

  def next_moves
    Enumerator.new do |yielder|
      @current_warriors.each do |(wid, (x, y))|
        move = [ wid, compute_move_from(x, y, wid) ]
        yielder << move
      end
    end
  end

  def compute_move_from x, y, wid
    state = {
      friendly_warriors: @current_warriors,
      enemy_warriors: @enemy_warriors,
      dead_warriors: @dead_warriors,
      friendly_base_location: @base_location,
      enemy_base_locations: @enemy_base_locations
    }
    move_mag = [0, 0]
    MOVES.each_with_index do |(_, get_mag), i|
      next if @move_chances[i].nil?
      if rand(100) < @move_chances[i]
        mag = get_mag.call(state.merge({ loc: [x, y], wid: wid}),
                         ->(target_loc){ self.class.toward([x, y], target_loc) },
                         ->(target_loc){ self.class.away_from([x, y], target_loc) })
        unless mag.nil?
          move_mag[0] += mag[0]
          move_mag[1] += mag[1]
        end
      end
    end
    constrain move_mag
    move_mag
  end
end


class BestGrownPlayer < MoldablePlayer
  def initialize name
    super name, [21, 88, 100, 23, 92, 89, 95, 99, 93, 8, 100, 0]
  end
end
