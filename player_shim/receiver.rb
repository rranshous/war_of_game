

class Receiver

  def initialize from_sim, to_sim, player
    @from_sim, @to_sim = from_simm, to_sim
    @player = player
  end

  def tick
    line = @from_sim.gets.chomp
    line_pieces = line.split
    case line_pieces.first
    when 'round start'
      @player.round_started compile_round_details @from_sim
    when 'gameover'
      @player.die if line_pieces.last == 'died'
      @player.win if line_pieces.last == 'win'
    else
      raise "unknown command: #{line}"
    end
  end


  private

  def self.compile_round_details data_stream
    warriors = []
    enemy_warriors = []
    dead_warriors = []
    line = @from_sim.gets.chomp
    line_pieces = line.split
    case line_pieces.first
    when 'round' # details end'
      # done streaming round's game state
      if line == 'round details end'
        return [ warriors, enemy_warriors, dead_warriors ]
      end
    when 'w'
      # data about our warrior
      wid, x, y = line_pieces[1..-1].map(&:to_i)
      warriors << [wid, [x, y]]
    when 'ew'
      # data about enemy warrior
      wid, x, y = line_pieces[1..-1].map(&:to_i)
      enemy_warriors << [wid, [x, y]]
    when 'dw'
      # data about dead warriors
      pid, x, y = line_pieces[1..-1]
      x, y = [x, y].map(&:to_i)
      dead_warriors << [pid, [x, y]]
    end
  end

end
