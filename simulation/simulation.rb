

class BattleRoyalSimulation
  def initialize players
    @round = 0
    @players = players
    @board_size = [100, 100]
    @num_of_warriors = 20
    @max_game_length = 1000
    @tick_time = 1
    @next_moves = []
    @warriors = {} # [player,warrior_id] = [x,y]
    @bases = {} # [player] = [x,y]
    @killed_warriors = [] # [player,warrior_id]
    place_random_bases
  end

  def tick
    if !game_over?
      spawn_warriors
      announce_round_to_players
      reset_killed_warriors
      reset_killed_bases
      wait_for_players_to_respond
      move_warriors
      fight_warriors
      reap_dead_warriors
      fight_warriors_and_bases
      reap_dead_bases
      notify_dead_players
    end
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
    puts "BOARD:"
    0.upto(@board_size[1]) do |y|
      0.upto(@board_size[0]) do |x|
        print board[[x,y]] || '.'
      end
      puts
    end
    puts
  end

  private

  def spawn_warriors
    @bases.each do |player, (x,y)|
      @warriors[[player,round]] = [x, y]
    end
  end

  def announce_round_to_players
    @players.each do |player|
      player.announce_round(warriors_for(player),
                            enemies_warriors_of(player),
                            enemy_bases_of(player),
                            recently_dead_warriors)
    end
  end

  # TODO: send game state
  def notify_dead_players
    @players.each(&:die)
  end

  def game_over?
    only_one_teams_base_alive? || only_one_teams_warriors_alive?
  end

  def only_one_teams_base_alive?
    @bases.length <= 1
  end

  def only_one_teams_warriors_alive?
    @warriors.map { |(player, _), _| player }.uniq.length <= 1
  end

  def reset_killed_warriors
    @killed_warriors = []
  end

  def reset_killed_bases
    @killed_bases = []
  end

  # TODO: send game state
  def wait_for_players_to_respond
    sleep @tick_time
    @next_moves = @players.map(&:next_moves)
  end


  def fight_warriors
    @killed_warriors += player_locations
                          .select{ |l, wds| wds.length > 1 }
                          .map{ |l, wds| wds - wds.sample(1) }
                          .flatten
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
    @next_moves.zip(@players).each_with_index do |players_moves, player, i|
      move_players_warriors(player, moves)
    end
  end

  # TODO: verify moves
  def move_players_warriors player, moves
    moves.each do |(warrior_id, new_x, new_y)|
      @warriors[[player,warrior_id]] = [new_x, new_y]
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
