
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
    if @prev_fitness
      # FU darwinning
      return @prev_fitness
    end
    # run tournament against random player, score how many
    # games lost
    this_player_type = ['Moldable', genotypes]
    striking_player_type = ['Striking']
    attack_player_type = ['Attack']
    grown2 = ['Moldable', [65, 48, 30, 22, 87, 16, 94, 63, 86, 74]]
    grown3 = ['Moldable', [14, 22, 38, 68, 80, 33, 99, 4, 78, 15]]
    grown4 = ['Moldable', [41, 40, 23, 93, 64, 21, 34, 81, 53, 56]]

    enemies = [striking_player_type, attack_player_type, grown2, grown3, grown4]
    loss_count = 0
    enemies.each do |enemy|
      tournament = Tournament.new [this_player_type, enemy], 200, 10
      results = tournament.run
      loss_count += results.count do |(winner, players)|
        i = players.index(this_player_type)
        i && i != winner
      end
    end
    @prev_fitness = loss_count
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
