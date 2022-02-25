# frozen_string_literal: true

require_relative "symbols"
require_relative "board"

class Game
  def initialize
    @board = Board.new
    @current = "White"
    @origin = []
    @movement = []
  end

  def play
    introduction
    loop do
      @board.print_board
      select_piece
      @board.color_origin(@origin)
      @board.print_board
      @board.move_piece(select_move)
      @current == "White" ? @current = "Black" : @current = "White"
    end
  end

  def select_piece
    puts "#{@current}'s Turn!\n"
    puts "Enter coordinates of the piece you want to move,"
    puts "enter [1] to save, or [0] to quit."
    loop do
      print "Input: "
      @origin = gets
      row = @origin[1].to_i - 1
      column = @origin[0].to_s.downcase.ord - 97
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

  private

  def introduction   
    puts <<~HEREDOC

    Welcome to Chess board game on Ruby terminal!
    Checkmate the opponent's king and win!
    Goodluck and have fun!

    Enter..
    [1] To start a player vs player game
    [2] To start a player vs computer game
    [3] To resume from saved game

    HEREDOC
    loop do
      print "Input: "
      input = gets[0].to_i
      break if input.between?(1,1)

      puts "Invalid input.. Try again."
    end
  end 

end # End of Game class!
