

class BattleRoyalSimulation
  def initialize players
    @players = players
    @board_size = [100, 100]
    @num_of_warriors = 20
    @max_game_length = 1000
    @tick_time = 1
    @next_moves = []
    @warriors = {}
    @bases = {}
    @killed_warriors = []
    place_random_bases
  end

  def tick
    while !game_over?
      spawn_warriors
      announce_round_to_players
      reset_killed_warriors
      wait_for_players_to_respond
      move_warriors
      fight_warriors
      reap_dead_warriors
      fight_warriors_and_bases
      notify_dead_players
    end
  end

  private

  def announce_round_to_players
    @players.each do |player|
      player.announce_round(warriors_for(player),
                            enemies_warriors_of(player),
                            enemy_bases_of(player),
                            recently_dead_warriors_for(player))

    end
  end

  def notify_dead_players
  end

  def game_over?
    only_one_teams_base_alive? || only_one_teams_warriors_alive?
  end

  def only_one_teams_base_alive?
  end

  def only_one_teams_warriors_alive?
  end

  def reset_killed_warriors
    @killed_warriors = []
  end

  def wait_for_players_to_respond
    sleep 1
    @next_moves = @players.map(&:next_moves)
  end

  def move_warriors
    @next_moves.zip(@players).each_with_index do |players_moves, player, i|
      move_warriors(player, moves)
    end
  end

  def fight_warriors
    @killed_warriors += player_locations
                          .select{ |l, wds| wds.length > 1 }
                          .map{ |l, wds| wds - wds.sample(1) }
                          .flatten
  end

  def fight_warriors_and_bases
    @killed_bases += @bases.zip(@players).select do |base_location, player|
    end
  end

  def reap_dead_warriors
    @killed_warriors.each do |warrior_description|
      @warriors.delete warrior_description
    end
  end

  # TODO: verify moves
  def move_warriors player, moves
    moves.each do |warrior_id, new_x, new_y|
      @warriors[[player,warrior_id]].location = [new_x, new_y]
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
