require 'open3'
require 'timeout'
require_relative '../simulation/simulation'
require_relative '../player/player'

module Parallelize
  def run
    puts "tournament RUNNING IN PARALLEL"
    results = Queue.new
    @player_types.combination(2).each do |game_player_types|
      threads = []
      @games_per_tournament.times do
        threads << Thread.new do
          winner, rounds = self.class.run_sim game_player_types, @max_rounds
          results << [winner, game_player_types, rounds]
        end
      end
      threads.each(&:join)
    end
    [].tap do |r|
      loop { r << results.shift(true) rescue break }
    end
  end

  def thread_pool
    threads = []
    2.times do
      threads << Thread.new do
        winner, rounds = self.class.run_sim game_player_types, @max_rounds
        results << [winner, game_player_types, rounds]
      end
    end
  end
end

class Tournament
  def initialize player_types, max_rounds=1000, games_per_tournament=20
    @player_types = player_types
    @max_rounds = max_rounds
    @games_per_tournament = games_per_tournament
  end

  def run
    results = []
    @player_types.combination(2).each do |game_player_types|
      @games_per_tournament.times do
        winner, rounds = self.class.run_sim game_player_types, @max_rounds
        results << [winner, game_player_types, rounds]
      end
    end
    results
  end

  private

  def self.run_sim player_types, max_rounds
    players = []
    player_types.each do |(player_type, arg)|
      player_klass = eval("#{player_type}Player")
      players << player_klass.new(player_type, arg) if arg
      players << player_klass.new(player_type) unless arg
    end

    sim = BattleRoyalSimulation.new players
    begin
      sim.tick
      #sim.print_board
      #sleep 0.2
      if sim.round >= max_rounds
        return [nil, :MAXROUNDS]
      end
    end while !sim.game_over?
    return [sim.winner, sim.round]
  end
end

class ThreadedTournament < Tournament
  def self.run_sim players, max_rounds
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
            sim.print_board
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
