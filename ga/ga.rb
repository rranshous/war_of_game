
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
    Darwinning::Gene.new(name: "chance of away from friendly warrior",
                         value_range: (0..100)),
    Darwinning::Gene.new(name: "chance of away from enemy warrior",
                         value_range: (0..100)),
  ]
  def fitness
    # run tournament against random player, score how many
    # games lost
    this_player_type = ['Moldable', genotypes]
    striking_player_type = ['Striking']
    random_player_type = ['Random']
    attack_player_type = ['Attack']
    enemies = [striking_player_type, random_player_type, attack_player_type]
    loss_count = 0
    enemies.each do |enemy|
      tournament = Tournament.new [this_player_type, enemy]
      results = tournament.run
      loss_count += results.count do |(winner, players)|
        i = players.index(this_player_type)
        i && i != winner
      end
    end
    puts "ga score: #{loss_count}"
    STDOUT.flush
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
