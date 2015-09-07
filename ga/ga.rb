
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
    random_player_exec = 'ruby ./run_player.rb random'
    tournament = Tournament.new [this_player_exec, random_player_exec]
    results = tournament.run
    loss_count = results.count{ |(w, _)| w != 0 }
    puts "ga score: #{loss_count}"
    return loss_count
  end
end

p = Darwinning::Population.new(
    organism: PlayerGrower, population_size: 100,
    fitness_goal: 0, generations_limit: 500
)
p.evolve!

p.best_member.nice_print # prints the member representing the solution

puts
puts "DONE"
