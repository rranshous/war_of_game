require_relative 'player_shim/receiver'
require_relative 'player/player'

$stdout = STDERR # remap puts
from_sim = STDIN
to_sim = STDOUT
mode = ARGV.shift

case mode
when 'random'
  puts "run player random"
  player = Player.new 'random'
when 'molded'
  puts "run player molded: #{ARGV.to_a}"
  player = MoldablePlayer.new 'molded', ARGV.to_a.map(&:to_i)
else
  puts "run player random"
  player = Player.new 'default'
end

receiver = Receiver.new from_sim, to_sim, player
puts "receiver starting"
loop do
  receiver.tick
  to_sim.flush
end
