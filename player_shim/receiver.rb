

class Receiver

  def initialize from_sim, to_sim, player
    @from_sim, @to_sim = from_sim, to_sim
    @player = player
  end

  def tick
    puts "receiver ticking"
    line = @from_sim.gets.chomp
    line_pieces = line.split
    case line
    when 'round start'
      puts "receiver round start"
      @player.round_started(*self.class.compile_round_details(@from_sim))
      puts "receiver calling for moves"
      @player.next_moves.each do |(wid, (x, y))|
        @to_sim.puts "w #{wid} #{x} #{y}"
      end
      puts "receiver done giving moves"
      @to_sim.puts "done"
    when /^gameover.*/
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

    loop do
      line = data_stream.gets.chomp
      line_pieces = line.split
      case line_pieces.first
      when 'round'
        if line == 'round details end'
          return [ warriors, enemy_warriors, dead_warriors ]
        end
      when 'w'
        wid, x, y = line_pieces[1..-1].map(&:to_i)
        warriors << [wid, [x, y]]
      when 'ew'
        wid, x, y = line_pieces[1..-1].map(&:to_i)
        enemy_warriors << [wid, [x, y]]
      when 'dw'
        pid, x, y = line_pieces[1..-1]
        x, y = [x, y].map(&:to_i)
        dead_warriors << [pid, [x, y]]
      end
    end
  end

end
