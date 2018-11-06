# Mini-project - Blackjack (Thinknetica Exercise)

require_relative 'card'
require_relative 'deck'
require_relative 'player'
require_relative 'bank'

class TheGame
  MAX_ALLOWED_CARDS = 3
  MAX_SCORE = 21

  def initialize
    @in_play    = false
    @player     = Player.new
    @dealer     = Player.new
    @game_bank  = Bank.new(0)
    @game_ended = false
  end

  def start
    ask_user_name
    ask_action
  end

  private

  def deal_cards
    check_game_ended

    if in_play?
      # If game started but player chooses a new deal then he looses
      @in_play = false
      @player.reset_cards
      @dealer.reset_cards
      @dealer.bank.replenish(@game_bank.withdraw(@game_bank.amount))  # Dealer takes all game's bank_amount
      show_message('Вы проиграли партию. Выберите раздать карты снова.')
      show_players_bank_amount
      check_players_empty_bank
    else
      puts '= ' * 50
      puts "Игра началась. Выдаем карты игроку и дилеру..."
      puts '= ' * 50
      puts
      puts "Банк игроков на начало игры:"
      show_players_bank_amount

      # Dealing the initial deck of cards
      @deck = Deck.new
      @deck.shuffle

      [@player, @dealer].map do |p|
        @game_bank.replenish(p.bank.withdraw(10))
        add_cards_to(p, 2)
      end

      @in_play = true

      puts 'Ставки сделаны:'
      show_players_bank_amount
      show_players_cards_and_values
      show_message("Взять карту или пропустить?(Ход переходит к Дилеру)")
    end
  end

  def hit
    check_game_ended

    # Add cards to player when he decides to get one more card
    if @player.cards.count < MAX_ALLOWED_CARDS and in_play?
      if @player.get_cards_value <= MAX_SCORE
        @player.add_card(@deck.deal_card)

        show_players_cards_and_values

        if @player.get_cards_value > 21
          @in_play = false
          @player.reset_cards
          @dealer.reset_cards
          @dealer.bank.replenish(@game_bank.withdraw(@game_bank.amount))  # Dealer takes all game's bank_amount
          show_message('Вы проиграли!')
          show_players_bank_amount
          check_players_empty_bank
        elsif @player.cards.count >= MAX_ALLOWED_CARDS
          stand # Ход передаем дилеру
        end
      end
    else
      show_message("Игра еще не началась. Надо раздать карты.") if @player.cards.count >= MAX_ALLOWED_CARDS || !@in_play
    end
  end

  def stand
    check_game_ended

    # Opening cards and count values
    if in_play?
      puts "Дилер ходит >>\n\n"

      while @dealer.get_cards_value < 17
        if @dealer.cards.count < MAX_ALLOWED_CARDS
          @dealer.add_card(@deck.deal_card)
        else
          break
        end
      end

      show_players_cards_and_values

      if @dealer.get_cards_value > 21
        @in_play = false
        @player.reset_cards
        @dealer.reset_cards
        @player.bank.replenish(@game_bank.withdraw(@game_bank.amount))  # Player takes all game's bank_amount
        show_message('Дилер проиграл :)')
      elsif @player.get_cards_value > 21
        @in_play = false
        @player.reset_cards
        @dealer.reset_cards
        @dealer.bank.replenish(@game_bank.withdraw(@game_bank.amount))  # Dealer takes all game's bank_amount
        show_message('Вы проиграли!')
      elsif @dealer.get_cards_value == @player.get_cards_value
        half_bank = @game_bank.amount / 2
        @in_play = false
        @player.reset_cards
        @dealer.reset_cards
        @player.bank.replenish(@game_bank.withdraw(half_bank))
        @dealer.bank.replenish(@game_bank.withdraw(half_bank))
        show_message('Ничья!')
      elsif @dealer.get_cards_value < @player.get_cards_value
        @in_play = false
        @player.reset_cards
        @dealer.reset_cards
        @player.bank.replenish(@game_bank.withdraw(@game_bank.amount))  # Player takes all game's bank_amount
        show_message('Дилер проиграл :)')
      else
        @in_play = false
        @player.reset_cards
        @dealer.reset_cards
        @dealer.bank.replenish(@game_bank.withdraw(@game_bank.amount))  # Dealer takes all game's bank_amount
        show_message('Вы проиграли!')
      end
      show_players_bank_amount
      check_players_empty_bank
    else
      show_message("Игра еще не началась. Надо раздать карты.")
    end
  end

  def in_play?
    @in_play
  end

  def game_ended?
    @game_ended
  end

  def show_message(text)
    puts "#{text}\n\n"
  end

  def ask_action
    loop do
      show_possible_actions
      begin
        choice = gets.chomp
        case choice
          when '0'  then show_possible_actions
          when '1'  then deal_cards
          when '2'  then hit
          when '3'  then stand
          else
            puts 'Вы вышли из программы.'
            break
        end
      rescue => e
        puts "::ERROR:: #{e.message}"
      end
    end
  end

  def show_possible_actions
    puts 'Выберите действие из списка ниже:'
    puts '1 - чтобы раздать карты (Игрок проиграет, если игра активна)'
    puts '2 - взять еще одну карту'
    puts '3 - пропустить ход (играет Дилер)'
    puts '0 - показать меню снова'
    puts
  end

  def add_cards_to(player_type, quantity)
    quantity.times { player_type.add_card(@deck.deal_card) }
  end

  def show_players_bank_amount
    puts "Банк игрока #{@player.name}: #{@player.bank.amount}"
    puts "Банк Дилера: #{@dealer.bank.amount}"
    puts "Банк Игры: #{@game_bank.amount}"
    puts
  end

  def show_players_cards_and_values
    puts "#{@player.name} #{@player}(#{@player.get_cards_value})"
    puts "Дилер имеет карты: #{@dealer.show_cards_as_hidden}(#{@dealer.get_cards_value})"
    puts
  end

  def ask_user_name
    while @player.name.to_s.empty? do
      print 'Введите ваше имя: '
      @player.name = gets.chomp
    end
    puts
  end

  def restart!
    @in_play    = false
    @game_ended = false
    @game_bank.reset
    @player.bank.reset
    @dealer.bank.reset
  end

  def check_game_ended
    if game_ended?
      puts 'Игра окончена!'
      puts 'Будем играть еще? (Y/N)'
      choice = gets.chomp.downcase

      if choice == 'y'
        restart!
        puts "Сброс завершен.\n\n"
      else
        puts 'Вы вышли из программы.'
        exit(0)
      end
    end
  end

  def check_players_empty_bank
    player_amount = @player.bank.amount
    dealer_amount = @dealer.bank.amount

    if player_amount == 0 && dealer_amount > player_amount
      @game_ended = true
      puts "Дилер выйграл игру. Банк игрока #{@player.name} пуст.\n\n"
    elsif dealer_amount == 0 && player_amount > dealer_amount
      puts "Игрок #{@player.name} выйграл игру. Банк дилера пуст.\n\n"
      @game_ended = true
    end
    deal_cards
  end

end

game = TheGame.new

game.start
