

class Receiver

  def initialize from_sim, to_sim, player
    @from_sim, @to_sim = from_sim, to_sim
    @player = player
  end

  def tick
    line = @from_sim.gets
    raise "receiver error: from sim pipe closed" if line.nil?
    line = line.chomp
    line_pieces = line.split
    case line
    when 'game start'
      @player.game_started(*self.class.compile_game_details(@from_sim))

    when 'round start'
      @player.round_started(*self.class.compile_round_details(@from_sim))
      @player.next_moves.each do |(wid, (x, y))|
        @to_sim.puts "w #{wid} #{x} #{y}"
      end
      @to_sim.puts "done"

    when /^gameover.*/
      @player.die if line_pieces.last == 'died'
      @player.win if line_pieces.last == 'win'

    else
      raise "unknown command: #{line}"
    end
  end

  private

  def self.compile_game_details data_stream
    base_location = [0, 0]

    loop do
      line = data_stream.gets.chomp
      line_pieces = line.split
      case line_pieces.first
      when 'game'
        if line == 'game details end'
          return [ base_location ]
        end
      when 'b'
        x, y = line_pieces[1..-1].map(&:to_i)
        base_location = [x, y]
      end
    end
  end

  def self.compile_round_details data_stream
    warriors = []
    enemy_warriors = []
    dead_warriors = []
    enemy_base_locations = []

    loop do
      line = data_stream.gets.chomp
      line_pieces = line.split
      case line_pieces.first
      when 'round'
        if line == 'round details end'
          return [ warriors, enemy_warriors, dead_warriors, enemy_base_locations]
        end
      when 'w'
        wid, x, y = line_pieces[1..-1].map(&:to_i)
        warriors << [wid, [x, y]]
      when 'ew'
        pid, x, y = line_pieces[1..-1].map(&:to_i)
        enemy_warriors << [pid, [x, y]]
      when 'dw'
        pid, x, y = line_pieces[1..-1]
        x, y = [x, y].map(&:to_i)
        dead_warriors << [pid, [x, y]]
      when 'eb'
        pid, x, y = line_pieces[1..-1].map(&:to_i)
        enemy_base_locations << [pid, [x, y]]
      end
    end
  end

end
