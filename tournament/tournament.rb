require 'open3'
require 'timeout'
require_relative '../simulation/simulation'
require_relative '../player/player'

class Tournament
  def initialize player_types
    @player_types = player_types
  end

  def run
    results = []
    @player_types.combination(2).each do |game_player_types|
      10.times do
        winner, rounds = self.class.run_sim game_player_types
        results << [winner, game_player_types, rounds]
      end
    end
    results
  end

  private

  def self.run_sim player_types
    players = []
    player_types.each do |(player_type, arg)|
      player_klass = eval("#{player_type}Player")
      players << player_klass.new(player_type, arg) if arg
      players << player_klass.new(player_type) unless arg
    end

    sim = BattleRoyalSimulation.new players
    begin
      begin
        Timeout::timeout(10) do # WHY CAN I GET TIMEOUTS ON TICKS?!
          sim.tick
          sim.print_board
          #sleep 0.5
        end
      rescue Timeout::Error
        puts "tournament tick timeout"
        return [nil, :timeout]
      end
    end while !sim.game_over? && sim.round < 100
    return [sim.winner, sim.round]
  end
end
