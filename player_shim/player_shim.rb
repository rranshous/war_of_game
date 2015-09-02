

class PlayerShim

  def initialize to_player, from_player
    @to_player, @from_player = to_player, from_player
  end

  def announce_round player_warriors, enemy_warriors, enemy_bases, dead
    @to_player.puts 'start round'
  end

  def die
  end

  def next_moves
    # [[ wid, x, y ]]
  end
end
