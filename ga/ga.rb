
# we want to play tournaments
# while growing players

require 'darwinning'
require 'thread'
require 'parallel'
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
      # compute each orgs fitness in a sub proc
      fitnesses = ::Parallel.map(@members) do |m|
        m.fitness
      end
      # set the organisms fitness
      @members.zip(fitnesses) { |m, f| m.fitness = f }
    end

    def parallel_evolve!
      puts "initial fitness check"
      parallel_fitness
      until evolution_over?
        make_next_generation!
        puts "after generation fitness check"
        parallel_fitness
      end
    end
  end
end

class PlayerGrower < Darwinning::Organism

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

  def fitness= f
    @prev_fitness = f
  end

  def log msg=nil
    print "[#{self.class}:#{self.object_id}] #{msg}\n"
    STDOUT.flush
  end

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
    #enemies << 'Bouncer'
    #enemies << 'Careful'
    #enemies << 'Attack'
    #enemies << ['Moldable', [31, 38, 75, 57, 74, 21, 69, 34, 92, 60]] # grown5
    #enemies << ['Moldable', [100, 77, 15, 46, 73, 3, 27, 7, 99, 55]] # grown7
    #enemies << ['Moldable', [45, 64, 83, 70, 81, 4, 10, 8, 89, 17]] # grown 12
    #enemies << ['Moldable', [32, 31, 65, 64, 92, 18, 6, 70, 99, 5]] # grown11
    enemies << ['Moldable', [51, 37, 4, 32, 96, 14, 0, 91, 95, 27]] # grown10
    enemies << 'Striking'

    log "starting #{this_player_type}"
    round_count = 0
    rounds = 50
    score = enemies.length * rounds
    enemies.each do |enemy|
      tournament = Tournament.new [this_player_type, enemy],
                                  500, rounds, false
      results = tournament.run
      win_count = results.count do |(winner, players)|
        winner == players.index(this_player_type)
      end
      log "wins #{win_count} / #{rounds} vs #{enemy}"
      round_count += rounds
      score -= win_count
      if win_count < rounds / 2 # short circuit if we lost most the rounds
        log "lost most rounds to enemy, stopping"
        break
      end
    end
    STDOUT.flush
    @prev_fitness = score
    log "score: #{score}"
    return score
  end
end

population_size = (ARGV.shift || 10).to_i
generation_limit = (ARGV.shift || 10).to_i
puts "Running GA; pop #{population_size} gens #{generation_limit}"
puts "V: 1.2"

p = Darwinning::Population.new(
    organism: PlayerGrower, population_size: population_size,
    fitness_goal: 0, generations_limit: generation_limit
)
p.parallel_evolve!

puts "RAN GA; pop #{population_size} gens #{generation_limit}"
puts "FOUND MOST FIT"
puts "#{p.object_id}] #{p.best_member.fitness } | #{p.best_member.to_s}"

puts
puts "DONE"
