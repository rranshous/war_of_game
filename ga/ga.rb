
# we want to play tournaments
# while growing players

require 'darwinning'
require_relative '../tournament/tournament.rb'

module Darwinning
  class Organism
    def to_s
      self.genotypes.map{|g| g.last }
    end
  end
end

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
    this_player_type = ['Moldable', genotypes.map{|k,v| v}]
    enemies = []
    enemies << 'Striking'
    enemies << 'Attack'
    enemies << 'Random'
    enemies << 'Careful'
    enemies << 'Bouncer'
    # grown5
    enemies << ['Moldable', [31, 38, 75, 57, 74, 21, 69, 34, 92, 60]]
    # grown7
    enemies << ['Moldable', [100, 77, 15, 46, 73, 3, 27, 7, 99, 55]]

    puts "ga testing: #{this_player_type}"
    loss_count = 0
    enemies.each do |enemy|
      tournament = Tournament.new [this_player_type, enemy],
                                  1000, 10, false
      results = tournament.run
      losses = results.count do |(winner, players)|
        i = players.index(this_player_type)
        i && i != winner
      end
      puts "ga losses in tournament: #{losses} vs #{enemy}"
      loss_count += losses
    end
    @prev_fitness = loss_count
    puts "ga score: #{loss_count} / #{10 * enemies.length}"
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

puts "RAN GA; pop #{population_size} gens #{generation_limit}"
puts "FOUND MOST FIT"
puts "#{p.best_member.fitness } | #{p.best_member.to_s}"

puts
puts "DONE"
