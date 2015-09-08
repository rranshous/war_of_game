

class BattleRoyalSimulation
  attr_reader :round

  def initialize players
    @round = 0
    @players = players
    @board_size = [20, 20]
    @max_warriors = 5
    @tick_time = 1
    @next_moves = [] # [[[wid,[x,y]]] ordered as players are
    @warriors = {} # [player,warrior_id] = [x,y]
    @bases = {} # [player] = [x,y]
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
    @warriors.each do |_, loc|
      board[loc] = 'W'
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
    @players.each do |player|
      player.round_started(warriors_of(player),
                           enemy_warriors_of(player),
                           recently_dead_warriors,
                           enemy_bases_of(player))
    end
  end

  def warriors_of player
    @warriors
      .select{ |(p, _), _| p == player }
      .to_a
      .map{ |((_, id), loc)| [id, loc] }
  end

  def enemy_warriors_of player
    #[pid, [x, y]]
    @warriors
      .select{ |((p, _), _)| p != player }
      .map{ |((p, _), loc)| [@players.index(p), loc] }
  end

  def recently_dead_warriors
    #[pid, [x, y]]
    @killed_warriors.map do |(player, wid)|
      [@players.index(player), @warriors[[player,wid]]]
    end
  end

  def enemy_bases_of player
    @bases.select{ |p, l| p != player}.to_a
          .map{ |p, l| [@players.index(p), l] }
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
    @killed_bases += @bases.select{ |bp, bl|
                        @warriors.detect{ |(wp, _), wl| wp != bp && wl == bl } }
                        .keys
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

  # TODO: verify moves
  def move_players_warriors player, moves
    moves.each do |(warrior_id, (new_x, new_y))|
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
