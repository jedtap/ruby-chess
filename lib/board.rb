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
    @dark = 44
    @light = 1
    @color = [[@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark]]
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
    piece = @board[row][column]

    case piece
      #when b_king || w_king
      #when b_queen || w_queen
      #when b_knight || w_knight
      #when b_bishop || w_bishop
      #when b_rook || w_rook
      when b_pawn
        return true if @board[row-1][column] == empty
        return true if white_pieces.any?(@board[row-1][column+1])
        return true if white_pieces.any?(@board[row-1][column-1])
      when w_pawn
        @color[row+1][column] = 41 if @board[row+1][column] == empty
        @color[row+1][column+1] = 41 if black_pieces.any?@board[row+1][column+1]
        @color[row+1][column-1] = 41 if black_pieces.any?@board[row+1][column-1]
        @color[row+2][column] = 41 if @board[row+2][column] == empty && row == 1
      end
  end # end of color moves

  def valid_select?(row, column, current)
    if current == "White" && white_pieces.any?(@board[row][column])
      return true if valid_moves?(row, column, @board[row][column])
    end

    if current == "Black" && black_pieces.any?(@board[row][column])
      return true if valid_moves?(row, column, @board[row][column])
    end

    false
  end

  def valid_moves?(row, column, piece)
    case piece
    #when b_king || w_king
    #when b_queen || w_queen
    #when b_knight || w_knight
    #when b_bishop || w_bishop
    #when b_rook || w_rook
    when b_pawn
      return true if @board[row-1][column] == empty
      return true if white_pieces.any?(@board[row-1][column+1])
      return true if white_pieces.any?(@board[row-1][column-1])
    when w_pawn
      return true if @board[row+1][column] == empty
      return true if black_pieces.any?(@board[row+1][column+1])
      return true if black_pieces.any?(@board[row+1][column-1])
    end
    false
  end

  def valid_area?(row, column)
    @color[row][column] == 41 ? true : false
  end

  def move_piece(coordinates)
    row_orig = coordinates[0]
    col_orig = coordinates[1]
    row_move = coordinates[2]
    col_move = coordinates[3]
    
    @board[row_move][col_move] = @board[row_orig][col_orig]
    @board[row_orig][col_orig] = empty
    restore_board_color
  end

  def restore_board_color
    @color = [[@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark]]
  end

end # End of board class!

#bg red = 41
