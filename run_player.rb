require_relative 'player_shim/receiver'
require_relative 'player/player'

$stdout = STDERR # remap puts
from_sim = STDIN
to_sim = STDOUT
mode = ARGV.shift

case mode
when 'random'
  player = Player.new 'random'
when 'molded'
  player = MoldablePlayer.new 'molded', ARGV.to_a.map(&:to_i)
when 'striking'
  player = StrikingPlayer.new 'striking'
when 'attack'
  player = AttackPlayer.new 'attack'
else
  player = Player.new 'default'
end

receiver = Receiver.new from_sim, to_sim, player
loop do
  receiver.tick
  to_sim.flush
end
