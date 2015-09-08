
# we want to play tournaments
# while growing players

require 'darwinning'
require_relative '../tournament/tournament.rb'

class PlayerGrower < Darwinning::Organism
  @@sim_loops = 10
  @name = "PlayerGrower"
  @genes = [
    Darwinning::Gene.new(name: "chance of north", value_range: (0..100)),
    Darwinning::Gene.new(name: "chance of east", value_range: (0..100)),
    Darwinning::Gene.new(name: "chance of south", value_range: (0..100)),
    Darwinning::Gene.new(name: "chance of west", value_range: (0..100)),
    Darwinning::Gene.new(name: "chance of toward enemy base",
                         value_range: (0..100)),
    Darwinning::Gene.new(name: "chance of toward friendly base",
                         value_range: (0..100)),
    Darwinning::Gene.new(name: "chance of toward enemy warrior",
                         value_range: (0..100)),
    Darwinning::Gene.new(name: "chance of toward friendly warrior",
                         value_range: (0..100)),
  ]
  def fitness
    # run tournament against random player, score how many
    # games lost
    this_player_exec = "ruby ./run_player.rb molded #{genotypes.join(' ')}"
    striking_player_exec = 'ruby ./run_player.rb striking'
    random_player_exec = 'ruby ./run_player.rb random'
    attack_player_exec = 'ruby ./run_player.rb attack'
    enemies = [striking_player_exec, random_player_exec, attack_player_exec]
    loss_count = 0
    enemies.each do |enemy|
      tournament = Tournament.new [this_player_exec, enemy]
      results = tournament.run
      loss_count += results.count do |(winner, players)|
        i = players.index(this_player_exec)
        i && i != winner
      end
    end
    puts "ga score: #{loss_count}"
    return loss_count
  end
end

population_size = (ARGV.shift || 10).to_i
generation_limit = (ARGV.shift || 10).to_i
puts "Running GA; pop #{population_size} gens #{generation_limit}"

p = Darwinning::Population.new(
    organism: PlayerGrower, population_size: population_size,
    fitness_goal: 0, generations_limit: generation_limit
)
p.evolve!

p.best_member.nice_print # prints the member representing the solution

puts
puts "DONE"
