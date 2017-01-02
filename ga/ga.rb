
# we want to play tournaments
# while growing players

require 'darwinning'
require 'thread'
require_relative '../tournament/tournament.rb'

def puts msg=nil
  print "#{msg}\n"
end

module Darwinning
  class Organism
    def to_s
      self.genotypes.map{|g| g.last }
    end
  end

  class Population
    def parallel_fitness
      threads = @members.map do |m|
        Thread.new do
          puts "START FITNESS COMPUTE IN THREAD"
          m.fitness
          puts "FINISH FITNESS COMPUTE IN THREAD"
        end
      end
      threads.map(&:join)
    end

    def parallel_evolve!
      parallel_fitness
      until evolution_over?
        make_next_generation!
        parallel_fitness
      end
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


    # score will always be out of 100
    # it will be the percent of lossess across all opponents
    # if it losses more than half the matches against an opponent
    # it does not move on to the next opponent
    # opponents should go up in difficulty

    # run tournament against random player, score how many
    # games lost
    this_player_type = ['Moldable', genotypes.map{|k,v| v}]
    enemies = []
    enemies << 'Random'
    enemies << 'Bouncer'
    enemies << 'Careful'
    enemies << ['Moldable', [31, 38, 75, 57, 74, 21, 69, 34, 92, 60]] # grown5
    enemies << ['Moldable', [100, 77, 15, 46, 73, 3, 27, 7, 99, 55]] # grown7
    enemies << 'Attack'
    enemies << 'Striking'

    puts "ga testing: #{this_player_type}"
    round_count = 0
    rounds = 10
    score = enemies.length * rounds
    enemies.each do |enemy|
      tournament = Tournament.new [this_player_type, enemy],
                                  1000, rounds, false
      results = tournament.run
      losses = results.count do |(winner, players)|
        i = players.index(this_player_type)
        i && i != winner
      end
      puts "ga losses in tournament: #{losses} / #{rounds} vs #{enemy}"
      win_count = rounds - losses
      round_count += rounds
      score -= win_count
      if losses > rounds / 2 # short circuit if we lost most the rounds
        puts "lost most rounds to enemy, stopping"
        break
      end
    end
    STDOUT.flush
    @prev_fitness = score
    puts "ga score: #{score}"
    return score
  end
end

population_size = (ARGV.shift || 10).to_i
generation_limit = (ARGV.shift || 10).to_i
puts "Running GA; pop #{population_size} gens #{generation_limit}"

p = Darwinning::Population.new(
    organism: PlayerGrower, population_size: population_size,
    fitness_goal: 0, generations_limit: generation_limit
)
p.parallel_evolve!

puts "RAN GA; pop #{population_size} gens #{generation_limit}"
puts "FOUND MOST FIT"
puts "#{p.best_member.fitness } | #{p.best_member.to_s}"

puts
puts "DONE"
