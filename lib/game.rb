# frozen_string_literal: true

require 'yaml'
require_relative "symbols"
require_relative "board"

class Game
  def initialize
    @board = Board.new
    @current = "White"
    @origin = []
    @movement = []
    @select_move = []
    @non_check_area = true
    @quit = false
    @save = false
  end

  def play
    introduction
    loop do
      loop do
        @board.print_board
        puts "Move makes your king in check! Try again..\n" if @non_check_area == false
        select_piece
        break if @quit == true
        break if @save == true

        @board.color_origin(@origin)
        @board.print_board
        @select_move = select_move
        @non_check_area = @board.non_check_area?(@select_move)
        break if @non_check_area == true
        
      end
      break if @quit == true
      break if @save == true

      @board.simulation_off
      @board.restore_board_color
      @board.valid_select?(@origin[0], @origin[1], @current)
      @board.color_origin(@origin)
      @board.move_piece(@select_move)
      break if @board.checkmate
      break if @board.stalemate

      @current == "White" ? @current = "Black" : @current = "White"
    end
    
    puts "\nEnd of game..."
    if @board.checkmate
      puts "#{@current} checkmate opponent for the victory! Well done!"
    elsif @board.stalemate
      puts "It's a draw! Great match."
    end
  end

  def select_piece
    puts "#{@current}'s Turn!\n"
    puts "Enter coordinates of the piece you want to move,"
    puts "enter [s] to save & quit, or [x] to quit without saving"
    loop do
      print "Input: "
      @origin = gets
      column = @origin[0].to_s.downcase.ord - 97

      if column == 18
        save
        @save = true
        return
      elsif column == 23
        @quit = true
        return
      end

      row = @origin[1].to_i - 1
      @origin = [row, column]
      return if row.between?(0,7) && column.between?(0,7) && @board.valid_select?(row, column, @current)

      puts "Invalid input.. Try again"
    end
  end

  def select_move
    puts "Enter coordinates of the of the location you want to move,"
    loop do
      print "Input: "
      @movement = gets
      row = @movement[1].to_i - 1
      column = @movement[0].to_s.downcase.ord - 97
      return [@origin[0], @origin[1], row, column, @board.valid_area?(row, column)] if @board.valid_area?(row, column)

      puts "Invalid input.. Try again"
    end
  end

  def load
    begin
      data = YAML.load(File.open("lib/save_game.yaml", "r").read)

      @current = data[:current]
      @origin = data[:origin]
      @movement = data[:movement]
      @select_move = data[:select_move]
      @non_check_area = data[:non_check_area]
      @quit = false
      @save = false

    rescue StandardError
      nil
    end
  end

  private

  def introduction   
    puts <<~HEREDOC
    Welcome to Chess board game on Ruby terminal!
    Checkmate the opponent's king and win!
    Goodluck and have fun!
    Enter..
    [1] To start a player vs player game
    [2] To resume from saved game
    HEREDOC
    loop do
      print "Input: "
      input = gets[0].to_i
      if input == 2
        load
        @board.load
        break
      end
      break if input.between?(1,2)

      puts "Invalid input.. Try again."
    end
  end 

  def save
    data = {

      current: @current,
      origin: @origin,
      movement: @movement,
      select_move: @select_move,
      non_check_area: @non_check_area,

    }
    file = File.open("lib/save_game.yaml","w")
    file.puts YAML.dump(data)
    file.close

    @board.save
  end

end # End of Game class!