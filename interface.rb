require_relative 'game'

class Interface
  def initialize
    @game = Game.new
  end

  def start_game
    @game.ask_user_name
    @game.ask_action
  end

end

interface = Interface.new
interface.start_game
