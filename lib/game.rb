# frozen_string_literal: true

require_relative "symbols"
require_relative "board"

class Game
  def initialize
    @board = Board.new
  end

  def play
    introduction
    @board.print_board
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
