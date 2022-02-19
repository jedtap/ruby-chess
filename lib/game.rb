# frozen_string_literal: true

require_relative "symbols"
require_relative "board"

class Game
  def initialize
    @board = Board.new
    @current = "White"
    @coordinates = []
  end

  def play
    introduction
    @board.print_board
    @coordinates = select_piece
    @board.color_move(@coordinates)
    @board.print_board
  end

  def select_piece
    puts "#{@current}'s Turn!\n"
    puts "Enter coordinates of the piece you want to move,"
    puts "enter [1] to save, or [0] to quit."
    loop do
      print "Input: "
      @coordinates = gets
      row = @coordinates[1].to_i - 1
      column = @coordinates[0].to_s.downcase.ord - 97
      return [row, column] if row.between?(0,7) && column.between?(0,7)

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
