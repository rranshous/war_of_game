require_relative 'simulation/simulation'
require_relative 'player/player'
require_relative 'player_shim/player_shim'
require_relative 'player_shim/receiver'
require_relative 'tournament/tournament'

require 'thread'
Thread.abort_on_exception = true

mode = ARGV.shift

case mode
when 'in-proc'
  player = Player.new
  player2 = Player.new
  sim = BattleRoyalSimulation.new [player, player2]

  begin
    sim.tick
    sim.print_board
    gets
  end while !sim.game_over?

when 'in-proc-streams'
  players = ([nil]*2).map{ Player.new }
  player_pipes = players.map{ [ IO.pipe, IO.pipe ] }
  player_shim_receivers = players.zip(player_pipes).map do |player, pipes|
    (r_from_shim, _), (_, w_to_shim) = pipes
    Receiver.new r_from_shim, w_to_shim, player
  end
  player_shims = players.zip(player_pipes).map do |_, pipes|
    (_, w_to_receiver), (r_from_receiver, _) = pipes
    PlayerShim.new w_to_receiver, r_from_receiver
  end

  sim = BattleRoyalSimulation.new player_shims
  rthreads = player_shim_receivers.map do |player_receiver|
    Thread.new(player_receiver) { |pr| loop { pr.tick } }
  end
  sim.print_board
  puts "WAITING ON INPUT"
  gets
  begin
    sim.tick
    sim.print_board
  end while !sim.game_over?
  sleep 0.5
  puts "killing threads"
  rthreads.each{ |t| Thread.kill(t); t.join }

when 'tournament'
  player_commands = ARGV.to_a.map{|cmd| cmd.split(' ', 2)}
  player_commands.each do |cmd_set|
    cmd_set[1] = eval(cmd_set[1]) if cmd_set.length > 1
  end
  puts "app creating tournament: #{player_commands.join('::')}"
  tournament = Tournament.new player_commands
  results = tournament.run
  puts "RESULTS: #{results}"
end

