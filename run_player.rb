require_relative 'player_shim/receiver'
require_relative 'player/player'

$stdout = STDERR # remap puts
from_sim = STDIN
to_sim = STDOUT

player = Player.new
receiver = Receiver.new from_sim, to_sim, player
puts "receiver starting"
loop do
  receiver.tick
end
