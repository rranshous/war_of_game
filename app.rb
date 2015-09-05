require_relative 'simulation/simulation'
require_relative 'player/player'


player = Player.new
player2 = Player.new
sim = BattleRoyalSimulation.new [player, player2]

begin
  sim.tick
  sim.print_board
  gets
end while !sim.game_over?
