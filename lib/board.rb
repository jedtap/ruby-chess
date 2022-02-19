# frozen_string_literal: true

require_relative "symbols"

class Board
  include Symbols

  def initialize
    @board = [[],[],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"], ["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"], ["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],[],[]]
    @board[0] = ["#{b_rook}","#{b_knight}","#{b_bishop}","#{b_queen}","#{b_king}","#{b_bishop}","#{b_knight}","#{b_rook}"]
    @board[1] = ["#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}"]
    @board[6] = ["#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}"]
    @board[7] = ["#{w_rook}","#{w_knight}","#{w_bishop}","#{w_queen}","#{w_king}","#{w_bishop}","#{w_knight}","#{w_rook}"]
  end

  def print_board
    row_num = 8
    puts "    a  b  c  d  e  f  g  h"
      @board.each do |row|
        print " #{row_num} "
        row.each do |cell|
          print cell
        end
        print " #{row_num} "
        row_num -= 1
        print "\n"
      end
    puts "    a  b  c  d  e  f  g  h"
  end

  def test_items
    puts "white:"
    puts "\e[30;44m \u2b24  \e[0m"
    puts "\e[30;44m \u2654  \e[0m"
  end
end

#bg red = 41

#black and white pieces 30 and 0

#bg blue = 44
#bg gray = 47

#8
#down
#1
#a right h

