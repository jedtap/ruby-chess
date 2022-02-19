# frozen_string_literal: true

require_relative "symbols"

class Board
  include Symbols

  def initialize
    @board = [[],[],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"], ["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"], ["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],[],[]]
    @board[0] = ["#{w_rook}","#{w_knight}","#{w_bishop}","#{w_queen}","#{w_king}","#{w_bishop}","#{w_knight}","#{w_rook}"]
    @board[1] = ["#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}"]
    @board[6] = ["#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}"]
    @board[7] = ["#{b_rook}","#{b_knight}","#{b_bishop}","#{b_queen}","#{b_king}","#{b_bishop}","#{b_knight}","#{b_rook}"]
    dark = 44
    light = 1
    @color = [[dark,light,dark,light,dark,light,dark,light], [light,dark,light,dark,light,dark,light,dark], [dark,light,dark,light,dark,light,dark,light], [light,dark,light,dark,light,dark,light,dark],[dark,light,dark,light,dark,light,dark,light], [light,dark,light,dark,light,dark,light,dark], [dark,light,dark,light,dark,light,dark,light], [light,dark,light,dark,light,dark,light,dark]]
  end

  def print_board
    Gem.win_platform? ? (system "cls") : (system "clear")
    row_num = 8
    puts "    a  b  c  d  e  f  g  h"
    for row in (7).downto(0)
      print " #{row_num} "
      for column in 0..7
        print "\e[#{@color[row][column]}m#{@board[row][column]}\e[0m"
      end
      print " #{row_num} "
      row_num -= 1
      print "\n"
    end
    puts "    a  b  c  d  e  f  g  h\n\n"
  end

  def color_move(coordinates)
    row = coordinates[0]
    column = coordinates[1]
    @color[row][column] = 42
  end

end # End of board class!

#bg red = 41
