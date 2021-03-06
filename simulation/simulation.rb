

class BattleRoyalSimulation
  attr_reader :round

  def initialize players
    @round = 0
    @players = players
    @board_size = [50, 20]
    @max_warriors = 50
    @tick_time = 1
    @view_distance = 5
    @next_moves = [] # [[[wid,[x,y]]] ordered as players are
    @warriors = {} # [player,warrior_id] = [x,y]
    @bases = {} # [player] = [x,y]
    @base_starting_health = 10
    @base_health = Hash[@players.map{ |p| [p, 10] }]
    @killed_warriors = [] # [player,warrior_id]
    place_random_bases
    announce_start_to_players
  end

  def tick
    spawn_warriors if @round < @max_warriors
    announce_round_to_players
    collect_players_moves
    reap_dead_warriors
    reset_killed_warriors
    reset_killed_bases
    move_warriors
    reset_pending_moves
    fight_warriors
    fight_warriors_and_bases
    reap_dead_bases
    notify_dead_players
    @round += 1
  end

  def print_board
    board = {}
    @bases.each do |player, loc|
      board[loc] = 'B'
    end
    @warriors.each do |((p, _), loc)|
      board[loc] = @players.index(p) || 'W'
    end
    if game_over?
      puts "WINNER: #{winner}"
    end
    alive_players.each do |player|
      puts "player #{@players.index(player)}: #{warriors_of(player).length}"
    end
    0.upto(@board_size[1]) do |y|
      0.upto(@board_size[0]) do |x|
        print board[[x,y]] || '.'
      end
      puts
    end
    puts
  end

  def game_over?
    only_one_teams_base_alive? || only_one_teams_warriors_alive?
  end

  def winner
    @players.index(@bases.keys.first) || @players.index(@warriors.first[0])
  end

  private

  def alive_players
    @players.select{ |p| @bases[p] }
  end

  def spawn_warriors
    @bases.each do |player, (x,y)|
      @warriors[[player,@round]] = [x, y]
    end
  end

  def announce_start_to_players
    @players.each do |player|
      player.game_started @bases[player]
    end
  end

  def announce_round_to_players
    alive_players.each do |(player, _)|
      warrior_locs = recently_dead_warrior_locations_visible_to(player)
      player.round_started(warriors_of(player),
                           enemy_warriors_of(player),
                           warrior_locs,
                           enemy_bases_of(player))
    end
  end

  def warriors_of player
    @warriors
      .select{ |(p, _), _| p == player }
      .reject{ |wd, _| @killed_warriors.include?(wd) }
      .map{ |((_, id), loc)| [id, loc] }
      .to_a
  end

  def enemy_warriors_of player
    #[pid, [x, y]]
    @warriors
      .select{ |((p, _), _)| p != player }
      .select{ |_, loc| can_be_seen_by_player(player, loc) }
      .map{ |((p, _), loc)| [@players.index(p), loc] }
  end

  def recently_dead_warrior_locations_visible_to player
    @killed_warriors
      .map { |p, wid| [p, @warriors[[p, wid]]] }
      .select{ |_, loc| can_be_seen_by_player(player, loc) }
      .map{ |(p, loc)| [@players.index(p), loc] }
  end

  def recently_dead_warriors
    #[pid, [x, y]]
    @killed_warriors.map do |(player, wid)|
      [@players.index(player), @warriors[[player,wid]]]
    end
  end

  def enemy_bases_of player
    @bases.select{ |p, l| p != player}.to_a
          .select{ |_, l| can_be_seen_by_player(player, l) }
          .map{ |p, l| [@players.index(p), l] }
  end

  def can_be_seen_by_player player, tloc
    warriors_of(player).detect do |_, wloc|
      dx, dy = [tloc[0] - wloc[0], tloc[1] - wloc[1]]
      dist = Math.sqrt(dx*dx + dy*dy)
      dist <= @view_distance
    end
  end

  # TODO: send game state
  def notify_dead_players
    @killed_bases.each(&:die)
  end

  def only_one_teams_base_alive?
    @bases.length <= 1 ?  @bases.keys.first : nil
  end

  def only_one_teams_warriors_alive?
    live_players = @warriors.map { |(player, _), _| player }.uniq
    live_players.length <= 1 ? live_players.first : nil
  end

  def reset_killed_warriors
    @killed_warriors = []
  end

  def reset_killed_bases
    @killed_bases = []
  end

  def collect_players_moves
    @next_moves = @players.map{ |p| p.next_moves.to_a }
  end

  def fight_warriors
    @killed_warriors += player_locations
                          .select{ |l, wds| wds.length > 1 }
                          .flat_map{ |l, wds| wds - wds.sample(1) }
  end

  def fight_warriors_and_bases
    hit_bases = @bases.select{ |bp, bl|
                          @warriors.detect{ |(wp, _), wl| wp != bp && wl == bl } }
                       .keys
    hit_bases.each { |player| @base_health[player] -= 1 }
    @killed_bases = @base_health.select{ |p, h| h <= 0 }.keys
  end

  def reap_dead_warriors
    @killed_warriors.each do |warrior_description|
      @warriors.delete warrior_description
    end
  end

  def reap_dead_bases
    @killed_bases.each do |player|
      @bases.delete player
    end
  end

  def move_warriors
    @next_moves.zip(@players).each do |players_moves, player|
      move_players_warriors(player, players_moves)
    end
  end

  def reset_pending_moves
    @next_moves = []
  end

  def move_players_warriors player, moves
    moves.each do |(warrior_id, (move_x, move_y))|
      current_loc = @warriors[[player, warrior_id]]
      next if current_loc.nil? # can't move dead warrior
      move_x = [[-1, move_x].max, 1].min
      move_y = [[-1, move_y].max, 1].min
      new_x = current_loc[0] + move_x
      new_y = current_loc[1] + move_y
      @warriors[[player,warrior_id]] = [
        [[0, new_x].max, @board_size[0]].min,
        [[0, new_y].max, @board_size[1]].min
      ]
    end
  end

  def player_locations
    {}.tap do |player_locations|
      @warriors.each do |warrior_description, warrior_position|
        (player_locations[warrior_position] ||= []) << warrior_description
      end
    end
  end

  def place_random_bases
    @bases = Hash[
      @players.zip(
        @players.reduce([]) do |base_positions, _|
          begin
            loc = [rand(0..@board_size[0]), rand(0..@board_size[1])]
          end until !base_positions.include?(loc)
          base_positions + [loc]
        end
      )
    ]
  end
end
