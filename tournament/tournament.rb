require 'open3'
require_relative '../simulation/simulation'
require_relative '../player_shim/player_shim'

class Tournament
  def initialize players
    @players = players
  end

  def run
    results = []
    @players.combination(2).each do |players|
      10.times do
        winner, rounds = self.class.run_sim players
        results << [winner, players, rounds]
      end
    end
    results
  end

  private

  def self.run_sim players
    player_threads = []
    player_shims = []
    players.each do |player|
      thread, shim = start_player player
      player_threads << thread
      player_shims << shim
    end

    sim = BattleRoyalSimulation.new player_shims
    begin
      check_all_players_alive! player_threads
      sim.tick
      # sim.print_board
      # sleep 1
    end while !sim.game_over? && sim.round < 100

    player_threads.each do |pthread|
      Process.kill("KILL", pthread.pid)
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
