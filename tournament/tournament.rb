require 'open3'
require 'timeout'
require 'parallel'
require_relative '../simulation/simulation'
require_relative '../player/player'
require_relative '../player_shim/player_shim'
require_relative '../player_shim/receiver'

module ParallelizeTournament
  def run
    player_combos = @player_types.combination(2).to_a
    puts "player_combos: #{player_combos}"
    ::Parallel.map(player_combos) do |game_player_types|
      puts "STARTING GAME BETWEEN #{game_player_types}"
      [].tap do |game_results|
        @num_games.times do
          winner, rounds = self.class.run_sim game_player_types,
                                              @max_rounds,
                                              @print_board,
                                              @sleep_time
          game_results << [winner, game_player_types, rounds]
        end
      end
      puts "FINISHING GAME BETWEEN #{game_player_types}"
    end.flatten
  end
end

class Tournament

  attr_writer :sleep_time

  def initialize player_types, max_rounds=1000, num_games=20, print_board=true
    @player_types = player_types
    @max_rounds = max_rounds
    @num_games = num_games
    @print_board = print_board
    @sleep_time = nil
  end

  def run
    results = []
    @player_types.combination(2).each do |game_player_types|
      @num_games.times do
        winner, rounds = self.class.run_sim game_player_types,
                                            @max_rounds,
                                            @print_board,
                                            @sleep_time
        results << [winner, game_player_types, rounds]
      end
    end
    results
  end

  private

  def self.run_sim player_types, max_rounds, print_board, sleep_time
    players = []
    player_types.each do |(player_type, arg)|
      player_klass = eval("#{player_type}Player")
      players << player_klass.new(player_type, arg) if arg
      players << player_klass.new(player_type) unless arg
    end

    sim = BattleRoyalSimulation.new players
    begin
      sim.tick
      sleep(sleep_time) if sleep_time
      sim.print_board if print_board
      if sim.round >= max_rounds
        return [nil, :MAXROUNDS]
      end
    end while !sim.game_over?
    return [sim.winner, sim.round]
  end
end

class ThreadedTournament < Tournament
  def self.run_sim players, max_rounds, print_board, sleep_time
    player_threads = []
    player_shims = []
    players.each do |player|
      thread, shim = start_player player
      player_threads << thread
      player_shims << shim
    end

    puts "tournament game starting; players: #{players.join(' :: ')}"

    sim = BattleRoyalSimulation.new player_shims
    begin
      begin
        check_all_players_alive! player_threads
        begin
          Timeout::timeout(10) do # WHY CAN I GET TIMEOUTS ON TICKS?!
            sleep(sleep_time) if sleep_time
            sim.print_board if print_board
            sim.tick
          end
        rescue Timeout::Error
          puts "tournament tick timeout"
          return [nil, :TIMEOUT]
        end
        if sim.round >= max_rounds
          sim.print_board
          return [nil, :MAXROUNDS]
        end
      end while !sim.game_over?
    ensure
      sim.print_board
      player_threads.each do |pthread|
        Process.kill("KILL", pthread.pid) rescue nil
      end
    end
    return [sim.winner, sim.round]
  end

  def self.check_all_players_alive! player_threads
    dead_players = player_threads.select{ |pthread| !pthread.alive? }
    if dead_players.length > 0
      raise "Player has died before the game started: #{dead_players}"
    end
  end

  def self.start_player player
    pin, pout, pthread = Open3.popen2(player)
    [pthread, PlayerShim.new(pin, pout)]
  end
end
