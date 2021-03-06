# frozen_string_literal: true

# Color cheat sheet:
#   bg_black    40
#   bg_red      41 --> Viable move
#   bg_green    42 --> Current piece
#   bg_brown    43 --> Castling
#   bg_blue     44 --> Dark color
#   bg_magenta  45 --> En passant capture
#   bg_cyan     46
#   bg_gray     47

require 'yaml'
require_relative "symbols"

class Board
  include Symbols

  def initialize
    @board = [["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"], ["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"], ["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"]]

    @board[0] = ["#{w_rook}","#{w_knight}","#{w_bishop}","#{w_queen}","#{w_king}","#{w_bishop}","#{w_knight}","#{w_rook}"]
    @board[1] = ["#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}"]
    @board[6] = ["#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}"]
    @board[7] = ["#{b_rook}","#{b_knight}","#{b_bishop}","#{b_queen}","#{b_king}","#{b_bishop}","#{b_knight}","#{b_rook}"]

    @dark = 44
    @light = 1
    @color = [[@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark]]

    @en_passant = []
    @en_passant_turn = 0

    @promotion = false
    @pawn_color = nil

    @b_castling = [true, true, true]
    @w_castling = [true, true, true]

    @eliminated = nil

    @check = false
    @king_in_check = nil
    @check_attacker = []
    @current = "White"

    @checkmate = false
    @stalemate = false
    @b_king_pos = [7, 4]
    @w_king_pos = [0, 4]
    @current_piece = nil
    @board_simulate = @board.clone.map(&:clone)

    @sim_b_king_pos = [7, 4]
    @sim_w_king_pos = [0, 4]

    @simulation = false
    @end_game_timer = 50

  end

  def print_board
    # Clear screen & initialize the label for the 8 rows
    Gem.win_platform? ? (system "cls") : (system "clear")
    row_num = 8

    # Main board printing
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

    puts "Check!\n\n" if @check == true

  end

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
    when b_pawn
      return false unless (row-1).between?(0,7)

      b_pawn_moveset(row, column)

      # En-passant attack
      if @en_passant_turn > 0
        if @en_passant.length >= 3
          @color[row-1][@en_passant[0]] = 45 if @board[row][column] == @board[row][@en_passant[2]]
        end
        if @en_passant.length >= 2
          @color[row-1][@en_passant[0]] = 45 if @board[row][column] == @board[row][@en_passant[1]]
        end
      end

      # First move pawn cases: double step & en-passant
      if row == 6
        @color[row-2][column] = 41 if @board[row-2][column] == empty
        @en_passant = [column]

        # Save pawns eligible to do en-passant against current player
        # En passant turn is set to 2: 1 turn after current player and other for enemy turn 
        if (column-1).between?(0,7)
          @en_passant << column-1 if @board[row-2][column-1] == w_pawn
          @en_passant_turn = 2
        end
        if (column+1).between?(0,7)
          @en_passant << column+1 if @board[row-2][column+1] == w_pawn
          @en_passant_turn = 2
        end
      end
      @promotion = true if (row-1) == 0
      @pawn_color = "Black"
    when w_pawn
      return false unless (row+1).between?(0,7)

      w_pawn_moveset(row, column)

      # En-passant attack
      if @en_passant_turn > 0
        if @en_passant.length >= 3
          @color[row+1][@en_passant[0]] = 45 if @board[row][column] == @board[row][@en_passant[2]]
        end
        if @en_passant.length >= 2
          @color[row+1][@en_passant[0]] = 45 if @board[row][column] == @board[row][@en_passant[1]]
        end
      end

      # First move pawn cases: double step & en-passant
      if row == 1
        @color[row+2][column] = 41 if @board[row+2][column] == empty
        @en_passant = [column]

        # Save pawns eligible to do en-passant against current player
        # En passant turn is set to 2: 1 turn after current player and other for enemy turn 
        if (column-1).between?(0,7)
          @en_passant << column-1 if @board[row+2][column-1] == b_pawn
          @en_passant_turn = 2
        end
        if (column+1).between?(0,7)
          @en_passant << column+1 if @board[row+2][column+1] == b_pawn
          @en_passant_turn = 2
        end
      end
      @promotion = true if (row+1) == 7
      @pawn_color = "White"

    when b_rook
      b_rook_moveset(row, column)
      return false unless @color.flatten.any?(41)

      @b_castling[0] = false if row == 7 && column == 0
      @b_castling[2] = false if row == 7 && column == 7
    when w_rook
      w_rook_moveset(row, column)
      return false unless @color.flatten.any?(41)

      @w_castling[0] = false if row == 0 && column == 0
      @w_castling[2] = false if row == 0 && column == 7
    when b_king
      b_king_moveset(row,column)

      # Castling logic
      if @b_castling[1] == true
        if @b_castling[0] == true && @board[row][column-1] == empty && @board[row][column-2] == empty && @board[row][column-3] == empty
          @color[row][column-2] = 43
        end
        if @b_castling[2] == true && @board[row][column+1] == empty && @board[row][column+2]
          @color[row][column+2] = 43
        end
      end
      return false unless @color.flatten.any?(41)
      @b_castling[1] = false
    when w_king
      w_king_moveset(row,column)

      # Castling logic
      if @w_castling[1] == true
        if @w_castling[0] == true && @board[row][column-1] == empty && @board[row][column-2] == empty && @board[row][column-3] == empty
          @color[row][column-2] = 43
        end
        if @w_castling[2] == true && @board[row][column+1] == empty && @board[row][column+2] == empty
          @color[row][column+2] = 43
        end
      end

      return false unless @color.flatten.any?(41)
      @w_castling[1] = false
    when b_knight
      b_knight_moveset(row, column)
    when w_knight
      w_knight_moveset(row, column)
    when b_bishop
      b_bishop_moveset(row, column)
    when w_bishop
      w_bishop_moveset(row, column)
    when b_queen
      b_rook_moveset(row, column)
      b_bishop_moveset(row,column)
    when w_queen
      w_rook_moveset(row, column)
      w_bishop_moveset(row,column)
    end

    return false unless @color.flatten.any?(41)
    @en_passant_turn -= 1
    true
  end

  def color_origin(coordinates)
    row     = coordinates[0]
    column  = coordinates[1]
    @color[row][column] = 42

    @current = "White" if white_pieces.any?(@board[row][column])
    @current = "Black" if black_pieces.any?(@board[row][column])
    @current_piece = @board[row][column]
  end

  def non_check_area?(coordinates)
    # Get row and column values of origin and target move
    row_orig = coordinates[0]
    col_orig = coordinates[1]
    row_move = coordinates[2]
    col_move = coordinates[3]

    restore_board_color
    @board_simulate = @board.clone.map(&:clone)
    @board_simulate[row_move][col_move] = @board_simulate[row_orig][col_orig]
    @board_simulate[row_orig][col_orig] = empty

    @sim_b_king_pos = [row_move, col_move] if @board_simulate[row_move][col_move] == b_king
    @sim_w_king_pos = [row_move, col_move] if @board_simulate[row_move][col_move] == w_king

    @simulation = true
    return true if i_king_in_danger == false

    restore_board_color
    @simulation = false
    false
  end

  def valid_area?(row, column)
    return true if @color[row][column] == 41 # add more rules
    return "en-passant" if @color[row][column] == 45 # add more rules
    return "castling" if @color[row][column] == 43 # add more rules
    false
  end

  def move_piece(coordinates)
    # Get row and column values of origin and target move
    row_orig = coordinates[0]
    col_orig = coordinates[1]
    row_move = coordinates[2]
    col_move = coordinates[3]

    # Moving piece occupies the new tile and leaves an empty tile behind
    @eliminated = @board[row_move][col_move]
    @board[row_move][col_move] = @board[row_orig][col_orig]
    @board[row_orig][col_orig] = empty

    # Update king's position
    @b_king_pos = [row_move, col_move] if @current_piece == b_king
    @w_king_pos = [row_move, col_move] if @current_piece == w_king

    # Deactivate castling for a rook w/ zero moves that got eliminated
    if @eliminated == b_rook && row_move == 7 && col_move == 0
      @b_castling[0] = false
    elsif @eliminated == b_rook && row_move == 7 && col_move == 7
      @b_castling[2] = false
    elsif @eliminated == w_rook && row_move == 0 && col_move == 0
      @w_castling[0] = false
    elsif @eliminated == w_rook && row_move == 0 && col_move == 7
      @w_castling[2] = false
    end

    # Eliminate en-passant piece
    @board[row_orig][col_move] = empty if coordinates[4] == "en-passant"

    # Castling: move rook to the opposite side of King
    castling(row_move, col_move) if coordinates[4] == "castling"

    # Pawn promotion
    pawn_promotion(row_move, col_move) if @promotion == true
    @promotion = false

    # Assess a check
    check_criteria(row_move, col_move, @board[row_move][col_move])

    # Assess checkmate criteria
    if @check == true
      @simulation = true
      checkmate_criteria if @check == true
      @simulation = false
    end

    # Capturing a piece resets end game timer
    @eliminated == empty ? @end_game_timer -= 1 : @end_game_timer = 50

    # Assess a stalemate
    stalemate_criteria

    restore_board_color
  end

  def restore_board_color
    @color = [[@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark]]
  end

  def pawn_promotion(row, column)
    input = 0
    puts <<~HEREDOC
    Pawn Promotion!
    Enter a number to upgrade your pawn to a new piece. 
    
    [1] Queen
    [2] Knight
    [3] Rook
    [4] Bishop

    HEREDOC
    loop do
      print "Input: "
      input = gets[0].to_i
      break if input.between?(1,4)

      puts "Invalid input.. Try again."
    end
    case input
    when 1
      @pawn_color == "White" ? @board[row][column] = w_queen : @board[row][column] = b_queen
    when 2
      @pawn_color == "White" ? @board[row][column] = w_knight : @board[row][column] = b_knight
    when 3
      @pawn_color == "White" ? @board[row][column] = w_rook : @board[row][column] = b_rook
    when 4
      @pawn_color == "White" ? @board[row][column] = w_bishop : @board[row][column] = b_bishop
    end
  end

  def castling(row, column)
    if row == 7 && column == 2
      @board[row][3] = @board[row][0]
      @board[row][0] = empty
      @b_castling[1] = false
    elsif row == 7 && column == 6
      @board[row][5] = @board[row][7]
      @board[row][7] = empty
      @b_castling[1] = false
    elsif row == 0 && column == 2
      @board[row][3] = @board[row][0]
      @board[row][0] = empty
      @w_castling[1] = false
    elsif row == 0 && column == 6
      @board[row][5] = @board[row][7]
      @board[row][7] = empty
      @w_castling[1] = false
    end
  end

  def b_rook_moveset(row, column)
    board = []
    @simulation == true ? board = @board_simulate.clone.map(&:clone) : board = @board.clone.map(&:clone)

    if (column+1).between?(0,7)
      for tile in 1..7 
        break if column+tile > 7
        break if black_pieces.any?(board[row][column+tile])
        @color[row][column+tile] = 41
        break if white_pieces.any?(board[row][column+tile])
      end
    end

    if (row+1).between?(0,7)
      for tile in 1..7 
        break if row+tile > 7
        break if black_pieces.any?(board[row+tile][column])
        @color[row+tile][column] = 41
        break if white_pieces.any?(board[row+tile][column])
      end
    end

    if (column-1).between?(0,7)
      for tile in 1..7 
        break if column-tile < 0
        break if black_pieces.any?(board[row][column-tile])
        @color[row][column-tile] = 41
        break if white_pieces.any?(board[row][column-tile])
      end
    end

    if (row-1).between?(0,7)
      for tile in 1..7 
        break if row-tile < 0
        break if black_pieces.any?(board[row-tile][column])
        @color[row-tile][column] = 41
        break if white_pieces.any?(board[row-tile][column])
      end
    end

  end
  
  def w_rook_moveset(row, column)
    board = []
    @simulation == true ? board = @board_simulate.clone.map(&:clone) : board = @board.clone.map(&:clone)

    if (column+1).between?(0,7)
      for tile in 1..7 
        break if column+tile > 7
        break if white_pieces.any?(board[row][column+tile])
        @color[row][column+tile] = 41
        break if black_pieces.any?(board[row][column+tile])
      end
    end

    if (row+1).between?(0,7)
      for tile in 1..7 
        break if row+tile > 7
        break if white_pieces.any?(board[row+tile][column])
        @color[row+tile][column] = 41
        break if black_pieces.any?(board[row+tile][column])
      end
    end

    if (column-1).between?(0,7)
      for tile in 1..7 
        break if column-tile < 0
        break if white_pieces.any?(board[row][column-tile])
        @color[row][column-tile] = 41
        break if black_pieces.any?(board[row][column-tile])
      end
    end

    if (row-1).between?(0,7)
      for tile in 1..7 
        break if row-tile < 0
        break if white_pieces.any?(board[row-tile][column])
        @color[row-tile][column] = 41
        break if black_pieces.any?(board[row-tile][column])
      end
    end
  end

  def b_bishop_moveset(row, column)
    board = []
    @simulation == true ? board = @board_simulate.clone.map(&:clone) : board = @board.clone.map(&:clone)

    if (column+1).between?(0,7) && (row+1).between?(0,7)
      for tile in 1..7 
        break if column+tile > 7 || row+tile > 7
        break if black_pieces.any?(board[row+tile][column+tile])
        @color[row+tile][column+tile] = 41
        break if white_pieces.any?(board[row+tile][column+tile])
      end
    end

    if (column-1).between?(0,7) && (row+1).between?(0,7)
      for tile in 1..7 
        break if column-tile < 0 || row+tile > 7
        break if black_pieces.any?(board[row+tile][column-tile])
        @color[row+tile][column-tile] = 41
        break if white_pieces.any?(board[row+tile][column-tile])
      end
    end

    if (row-1).between?(0,7) && (column-1).between?(0,7)
      for tile in 1..7
        break if row-tile < 0 || column-tile < 0
        break if black_pieces.any?(board[row-tile][column-tile])
        @color[row-tile][column-tile] = 41
        break if white_pieces.any?(board[row-tile][column-tile])
      end
    end

    if (row-1).between?(0,7) && (column+1).between?(0,7)
      for tile in 1..7 
        break if row-tile < 0 || column+tile > 7
        break if black_pieces.any?(board[row-tile][column+tile])
        @color[row-tile][column+tile] = 41
        break if white_pieces.any?(board[row-tile][column+tile])
      end
    end
  end

  def w_bishop_moveset(row, column)
    board = []
    @simulation == true ? board = @board_simulate.clone.map(&:clone) : board = @board.clone.map(&:clone)

    if (column+1).between?(0,7) && (row+1).between?(0,7)
      for tile in 1..7 
        break if column+tile > 7 || row+tile > 7
        break if white_pieces.any?(board[row+tile][column+tile])
        @color[row+tile][column+tile] = 41
        break if black_pieces.any?(board[row+tile][column+tile])
      end
    end

    if (column-1).between?(0,7) && (row+1).between?(0,7)
      for tile in 1..7 
        break if column-tile < 0 || row+tile > 7
        break if white_pieces.any?(board[row+tile][column-tile])
        @color[row+tile][column-tile] = 41
        break if black_pieces.any?(board[row+tile][column-tile])
      end
    end

    if (row-1).between?(0,7) && (column-1).between?(0,7)
      for tile in 1..7
        break if row-tile < 0 || column-tile < 0
        break if white_pieces.any?(board[row-tile][column-tile])
        @color[row-tile][column-tile] = 41
        break if black_pieces.any?(board[row-tile][column-tile])
      end
    end

    if (row-1).between?(0,7) && (column+1).between?(0,7)
      for tile in 1..7 
        break if row-tile < 0 || column+tile > 7
        break if white_pieces.any?(board[row-tile][column+tile])
        @color[row-tile][column+tile] = 41
        break if black_pieces.any?(board[row-tile][column+tile])
      end
    end
  end

  def b_pawn_moveset(row, column)
    return unless (row-1).between?(0,7)
    board = []
    @simulation == true ? board = @board_simulate.clone.map(&:clone) : board = @board.clone.map(&:clone)

    if board[row-1][column] == empty
      @color[row-1][column] = 41
    end
    if (column+1).between?(0,7)
      @color[row-1][column+1] = 41 if white_pieces.any?(board[row-1][column+1])
    end
    if (column-1).between?(0,7)
      @color[row-1][column-1] = 41 if white_pieces.any?(board[row-1][column-1])
    end
  end

  def w_pawn_moveset(row, column)
    return unless (row+1).between?(0,7)
    board = []
    @simulation == true ? board = @board_simulate.clone.map(&:clone) : board = @board.clone.map(&:clone)

    if board[row+1][column] == empty
      @color[row+1][column] = 41
    end
    if (column+1).between?(0,7)
      @color[row+1][column+1] = 41 if black_pieces.any?(board[row+1][column+1])
    end
    if (column-1).between?(0,7)
      @color[row+1][column-1] = 41 if black_pieces.any?(board[row+1][column-1])
    end
  end

  def b_knight_moveset(row, column)
    board = []
    @simulation == true ? board = @board_simulate.clone.map(&:clone) : board = @board.clone.map(&:clone)

    if (column+2).between?(0,7)
      if (row+1).between?(0,7)
        @color[row+1][column+2] = 41 if board[row+1][column+2] == empty || white_pieces.any?(board[row+1][column+2])
      end
      if (row-1).between?(0,7)
        @color[row-1][column+2] = 41 if board[row-1][column+2] == empty || white_pieces.any?(board[row-1][column+2])
      end
    end
    if (column-2).between?(0,7)
      if (row+1).between?(0,7)
        @color[row+1][column-2] = 41 if board[row+1][column-2] == empty || white_pieces.any?(board[row+1][column-2])
      end
      if (row-1).between?(0,7)
        @color[row-1][column-2] = 41 if board[row-1][column-2] == empty || white_pieces.any?(board[row-1][column-2])
      end
    end
    if (row+2).between?(0,7)
      if (column+1).between?(0,7)
        @color[row+2][column+1] = 41 if board[row+2][column+1] == empty || white_pieces.any?(board[row+2][column+1])
      end
      if (column-1).between?(0,7)
        @color[row+2][column-1] = 41 if board[row+2][column-1] == empty || white_pieces.any?(board[row+2][column-1])
      end
    end
    if (row-2).between?(0,7)
      if (column+1).between?(0,7)
        @color[row-2][column+1] = 41 if board[row-2][column+1] == empty || white_pieces.any?(board[row-2][column+1])
      end
      if (column-1).between?(0,7)
        @color[row-2][column-1] = 41 if board[row-2][column-1] == empty || white_pieces.any?(board[row-2][column-1])
      end
    end
  end

  def w_knight_moveset(row, column)
    board = []
    @simulation == true ? board = @board_simulate.clone.map(&:clone) : board = @board.clone.map(&:clone)

    if (column+2).between?(0,7)
      if (row+1).between?(0,7)
        @color[row+1][column+2] = 41 if board[row+1][column+2] == empty || black_pieces.any?(board[row+1][column+2])
      end
      if (row-1).between?(0,7)
        @color[row-1][column+2] = 41 if board[row-1][column+2] == empty || black_pieces.any?(board[row-1][column+2])
      end
    end
    if (column-2).between?(0,7)
      if (row+1).between?(0,7)
        @color[row+1][column-2] = 41 if board[row+1][column-2] == empty || black_pieces.any?(board[row+1][column-2])
      end
      if (row-1).between?(0,7)
        @color[row-1][column-2] = 41 if board[row-1][column-2] == empty || black_pieces.any?(board[row-1][column-2])
      end
    end
    if (row+2).between?(0,7)
      if (column+1).between?(0,7)
        @color[row+2][column+1] = 41 if board[row+2][column+1] == empty || black_pieces.any?(board[row+2][column+1])
      end
      if (column-1).between?(0,7)
        @color[row+2][column-1] = 41 if board[row+2][column-1] == empty || black_pieces.any?(board[row+2][column-1])
      end
    end
    if (row-2).between?(0,7)
      if (column+1).between?(0,7)
        @color[row-2][column+1] = 41 if board[row-2][column+1] == empty || black_pieces.any?(board[row-2][column+1])
      end
      if (column-1).between?(0,7)
        @color[row-2][column-1] = 41 if board[row-2][column-1] == empty || black_pieces.any?(board[row-2][column-1])
      end
    end
  end

  def check_criteria(row, column, piece)
    restore_board_color
    @check = false

    case piece
    when b_pawn
      b_pawn_moveset(row, column)
    when w_pawn
      w_pawn_moveset(row, column)
    when b_rook
      b_rook_moveset(row, column)
    when w_rook
      w_rook_moveset(row, column)
    when b_bishop
      b_bishop_moveset(row, column)
    when w_bishop
      w_bishop_moveset(row, column)
    when b_knight
      b_knight_moveset(row, column)
    when w_knight
      w_knight_moveset(row, column)
    when b_queen
      b_rook_moveset(row, column)
      b_bishop_moveset(row, column)
    when w_queen
      w_rook_moveset(row, column)
      w_bishop_moveset(row, column)
    end

    @color.flatten.each_with_index do |item, index|
      @check = true if @current == "Black" && @board.flatten[index] == w_king && item == 41
      @check = true if @current == "White" && @board.flatten[index] == b_king && item == 41
      if @check == true
        @check_attacker = [row, column, piece]
        @current == "White" ? @king_in_check = "Black" : @king_in_check = "White"
        return
      end
    end

  end

  def checkmate
    @checkmate
  end

  def stalemate
    @stalemate
  end
  
  def checkmate_criteria
    @checkmate = true if check_move_out == false && check_block == false && check_takedown == false
  end

  def check_move_out

    # Test if the Black King can move/attack to a square w/o being in check
    if @current == "White"
      row = @b_king_pos[0]
      column = @b_king_pos[1]

      if (column+1).between?(0,7)

        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if @board_simulate[row][column+1] == empty || white_pieces.any?(@board[row][column+1])
          @board_simulate[row][column+1] = @board_simulate[row][column]
          @board_simulate[row][column] = empty
          @sim_b_king_pos = [row, column+1]
          return true if king_in_danger == false
        end

        
        if (row+1).between?(0,7)

          restore_board_color
          @board_simulate = @board.clone.map(&:clone)
          if @board_simulate[row+1][column+1] == empty || white_pieces.any?(@board[row+1][column+1])
            @board_simulate[row+1][column+1] = @board_simulate[row][column]
            @board_simulate[row][column] = empty
            @sim_b_king_pos = [row+1, column+1]
            return true if king_in_danger == false
          end

        end

        if (row-1).between?(0,7)

          restore_board_color
          @board_simulate = @board.clone.map(&:clone)
          if @board_simulate[row-1][column+1] == empty || white_pieces.any?(@board[row-1][column+1])
            @board_simulate[row-1][column+1] = @board_simulate[row][column]
            @board_simulate[row][column] = empty
            @sim_b_king_pos = [row-1, column+1]
            return true if king_in_danger == false
          end

        end

      end

      if (column-1).between?(0,7)

        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if @board_simulate[row][column-1] == empty || white_pieces.any?(@board[row][column-1])
          @board_simulate[row][column-1] = @board_simulate[row][column]
          @board_simulate[row][column] = empty
          @sim_b_king_pos = [row, column-1]
          return true if king_in_danger == false
        end


        if (row+1).between?(0,7)

          restore_board_color
          @board_simulate = @board.clone.map(&:clone)
          if @board_simulate[row+1][column-1] == empty || white_pieces.any?(@board[row+1][column-1])
            @board_simulate[row+1][column-1] = @board_simulate[row][column]
            @board_simulate[row][column] = empty
            @sim_b_king_pos = [row+1, column-1]
            return true if king_in_danger == false
          end

        end

        if (row-1).between?(0,7)

          restore_board_color
          @board_simulate = @board.clone.map(&:clone)
          if @board_simulate[row-1][column-1] == empty || white_pieces.any?(@board[row-1][column-1])
            @board_simulate[row-1][column-1] = @board_simulate[row][column]
            @board_simulate[row][column] = empty
            @sim_b_king_pos = [row-1, column-1]
            return true if king_in_danger == false
          end

        end

      end

      if (row+1).between?(0,7)

        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if @board_simulate[row+1][column] == empty || white_pieces.any?(@board[row+1][column])
          @board_simulate[row+1][column] = @board_simulate[row+1][column]
          @board_simulate[row+1][column] = empty
          @sim_b_king_pos = [row+1, column]
          return true if king_in_danger == false
        end

      end

      if (row-1).between?(0,7)

        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if @board_simulate[row-1][column] == empty || white_pieces.any?(@board[row-1][column])
          @board_simulate[row-1][column] = @board_simulate[row-1][column]
          @board_simulate[row-1][column] = empty
          @sim_b_king_pos = [row-1, column]
          return true if king_in_danger == false
        end

      end

    end 

    # Test if the White King can move/attack to a square w/o being in check
    if @current == "Black"
      row = @w_king_pos[0]
      column = @w_king_pos[1]

      if (column+1).between?(0,7)

        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if @board_simulate[row][column+1] == empty || black_pieces.any?(@board[row][column+1])
          @board_simulate[row][column+1] = @board_simulate[row][column]
          @board_simulate[row][column] = empty
          @sim_w_king_pos = [row, column+1]
        end
        return true if king_in_danger == false
        
        if (row+1).between?(0,7)

          restore_board_color
          @board_simulate = @board.clone.map(&:clone)
          if @board_simulate[row+1][column+1] == empty || black_pieces.any?(@board[row+1][column+1])
            @board_simulate[row+1][column+1] = @board_simulate[row][column]
            @board_simulate[row][column] = empty
            @sim_w_king_pos = [row+1, column+1]
          end
          return true if king_in_danger == false

        end

        if (row-1).between?(0,7)

          restore_board_color
          @board_simulate = @board.clone.map(&:clone)
          if @board_simulate[row-1][column+1] == empty || black_pieces.any?(@board[row-1][column+1])
            @board_simulate[row-1][column+1] = @board_simulate[row][column]
            @board_simulate[row][column] = empty
            @sim_w_king_pos = [row-1, column+1]
          end
          return true if king_in_danger == false

        end

      end

      if (column-1).between?(0,7)

        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if @board_simulate[row][column-1] == empty || black_pieces.any?(@board[row][column-1])
          @board_simulate[row][column-1] = @board_simulate[row][column]
          @board_simulate[row][column] = empty
          @sim_w_king_pos = [row, column-1]
        end
        return true if king_in_danger == false
        
        if (row+1).between?(0,7)

          restore_board_color
          @board_simulate = @board.clone.map(&:clone)
          if @board_simulate[row+1][column-1] == empty || black_pieces.any?(@board[row+1][column-1])
            @board_simulate[row+1][column-1] = @board_simulate[row][column]
            @board_simulate[row][column] = empty
            @sim_w_king_pos = [row+1, column-1]
          end
          return true if king_in_danger == false

        end

        if (row-1).between?(0,7)

          restore_board_color
          @board_simulate = @board.clone.map(&:clone)
          if @board_simulate[row-1][column-1] == empty || black_pieces.any?(@board[row-1][column-1])
            @board_simulate[row-1][column-1] = @board_simulate[row][column]
            @board_simulate[row][column] = empty
            @sim_w_king_pos = [row-1, column-1]
          end
          return true if king_in_danger == false

        end

      end

      if (row+1).between?(0,7)

        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if @board_simulate[row+1][column] == empty || black_pieces.any?(@board[row+1][column])
          @board_simulate[row+1][column] = @board_simulate[row+1][column]
          @board_simulate[row+1][column] = empty
          @sim_w_king_pos = [row+1, column]
        end
        return true if king_in_danger == false
        
      end

      if (row-1).between?(0,7)

        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if @board_simulate[row-1][column] == empty || black_pieces.any?(@board[row-1][column])
          @board_simulate[row-1][column] = @board_simulate[row-1][column]
          @board_simulate[row-1][column] = empty
          @sim_w_king_pos = [row-1, column]
        end
        return true if king_in_danger == false

      end

    end

    false
  end

  def check_block
    return false if non_blockable_pieces.any?(@check_attacker[2])

    vert = "n"
    hori = "n"
    ori = nil

    tiles = []
    king_pos = []
    @current == "Black" ? king_pos = @w_king_pos : king_pos = @b_king_pos

    # Identify king orientation: up, down, left, or right side of attacker?
    vert = "u" if @check_attacker[0] < king_pos[0]
    vert = "d" if @check_attacker[0] > king_pos[0]
    hori = "r" if @check_attacker[1] < king_pos[1]
    hori = "l" if @check_attacker[1] > king_pos[1]    
    ori = vert + hori

    # Save all squares between the attacker and king
    case ori
    when "nr"
      for i in 1..6
        break if @check_attacker[1] + i == king_pos[1]
        tiles << [king_pos[0], @check_attacker[1] + i]
      end
    when "un"
      for i in 1..6
        break if @check_attacker[0] + i == king_pos[0]
        tiles << [@check_attacker[0] + i, king_pos[1]]
      end
    when "nl"
      for i in 1..6
        break if king_pos[1] + i == @check_attacker[1]
        tiles << [king_pos[0], king_pos[1] + i]
      end
    when "dn"
      for i in 1..6
        break if king_pos[0] + i == @check_attacker[0]
        tiles << [king_pos[0] + i, king_pos[1]]
      end
    when "ur"
      for i in 1..6
        break if @check_attacker[0] + i == king_pos[0]
        tiles << [@check_attacker[0] + i, @check_attacker[1] + i]
      end
    when "dl"
      for i in 1..6
        break if king_pos[0] + i == @check_attacker[0]
        tiles << [king_pos[0] + i, king_pos[1] + i]
      end
    when "dr"
      for i in 1..6
        break if @check_attacker[0] - i == king_pos[0]
        tiles << [@check_attacker[0] - i, @check_attacker[1] + i]
      end
    when "ul"
      for i in 1..6
        break if king_pos[0] - i == @check_attacker[0]
        tiles << [king_pos[0] - i, king_pos[1] + i]
      end
    end # end of case!

    @simulation = true
    units = tiles.length - 1
    row = 0
    col = 0

    # For each square, find a black ally to block
    if @current == "White"
      for i in 0..units
        row = tiles[i][0]
        col = tiles[i][1]
        
        # Can a pawn block?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if (row + 1).between?(0,7)
          if @board_simulate[row + 1][col] == b_pawn
            @board_simulate[row][col] = b_pawn
            @board_simulate[row + 1][col] = empty
            return true if king_in_danger == false
          end
        end

        # Can a pawn block via double jump?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if (row + 2).between?(0,7) && (row + 1).between?(0,7) && row + 2 == 6
          if @board_simulate[row + 2][col] == b_pawn && @board_simulate[row + 1][col] == empty
            @board_simulate[row][col] = b_pawn
            @board_simulate[row + 2][col] = empty
            return true if king_in_danger == false
          end
        end

        # Can a rook block?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        w_rook_moveset(row, col)
        @color.flatten.each_with_index do |item, index|
          if item == 41 && @board_simulate.flatten[index] == b_rook
            @board_simulate[row][col] = b_rook
            @board_simulate[index/8][index%8] = empty
            return true if king_in_danger == false
          end
        end

        # Can a bishop block?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        w_bishop_moveset(row, col)
        @color.flatten.each_with_index do |item, index|
          if item == 41 && @board_simulate.flatten[index] == b_bishop
            @board_simulate[row][col] = b_bishop
            @board_simulate[index/8][index%8] = empty
            return true if king_in_danger == false
          end
        end

        # Can a knight block?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        w_knight_moveset(row, col)
        @color.flatten.each_with_index do |item, index|
          if item == 41 && @board_simulate.flatten[index] == b_knight
            @board_simulate[row][col] = b_knight
            @board_simulate[index/8][index%8] = empty
            return true if king_in_danger == false
          end
        end

        # Can the queen block?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        w_rook_moveset(row, col)
        w_bishop_moveset(row, col)
        @color.flatten.each_with_index do |item, index|
          if item == 41 && @board_simulate.flatten[index] == b_queen
            @board_simulate[row][col] = b_queen
            @board_simulate[index/8][index%8] = empty
            return true if king_in_danger == false
          end
        end

      end # End of for-loop
    end # End white

    # For each square, find a white ally to block
    if @current == "Black"
      for i in 0..units
        row = tiles[i][0]
        col = tiles[i][1]

        # Can a pawn block?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if (row - 1).between?(0,7)
          if @board_simulate[row - 1][col] == w_pawn
            @board_simulate[row][col] = w_pawn
            @board_simulate[row - 1][col] = empty
            return true if king_in_danger == false
          end
        end

        # Can a pawn block via double jump?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        if (row - 2).between?(0,7) && (row - 1).between?(0,7) && row - 2 == 1
          if @board_simulate[row - 2][col] == w_pawn && @board_simulate[row - 1][col] == empty
            @board_simulate[row][col] = w_pawn
            @board_simulate[row - 2][col] = empty
            return true if king_in_danger == false
          end
        end

        # Can a rook block?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        b_rook_moveset(row, col)
        @color.flatten.each_with_index do |item, index|
          if item == 41 && @board_simulate.flatten[index] == w_rook
            @board_simulate[row][col] = w_rook
            @board_simulate[index/8][index%8] = empty
            return true if king_in_danger == false
          end
        end


        # Can a bishop block?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        b_bishop_moveset(row, col)
        @color.flatten.each_with_index do |item, index|
          if item == 41 && @board_simulate.flatten[index] == w_bishop
            @board_simulate[row][col] = w_bishop
            @board_simulate[index/8][index%8] = empty
            return true if king_in_danger == false
          end
        end

        # Can a knight block?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        b_knight_moveset(row, col)
        @color.flatten.each_with_index do |item, index|
          if item == 41 && @board_simulate.flatten[index] == w_knight
            @board_simulate[row][col] = w_knight
            @board_simulate[index/8][index%8] = empty
            return true if king_in_danger == false
          end
        end

        # Can the queen block?
        restore_board_color
        @board_simulate = @board.clone.map(&:clone)
        b_rook_moveset(row, col)
        b_bishop_moveset(row, col)
        @color.flatten.each_with_index do |item, index|
          if item == 41 && @board_simulate.flatten[index] == w_queen
            @board_simulate[row][col] = w_queen
            @board_simulate[index/8][index%8] = empty
            return true if king_in_danger == false
          end
        end

      end # End of for-loop


    end # end black 

    return false
  end

  def check_takedown

    # Can enemy black piece be taken down?
    if black_pieces.any?(@check_attacker[2])

      # Takedown from a pawn?
      restore_board_color
      @board_simulate = @board.clone.map(&:clone)
      b_pawn_moveset(@check_attacker[0], @check_attacker[1])
      @color.flatten.each_with_index do | item, index | 
        if item == 41 && @board_simulate.flatten[index] == w_pawn
          @board_simulate[@check_attacker[0]][@check_attacker[1]] = w_pawn
          @board_simulate[index/8][index%8] = empty
          return true if king_in_danger == false
        end
      end

      # Takedown from a rook?
      restore_board_color
      @board_simulate = @board.clone.map(&:clone)
      b_rook_moveset(@check_attacker[0], @check_attacker[1])
      @color.flatten.each_with_index do | item, index | 
        if item == 41 && @board_simulate.flatten[index] == w_rook
          @board_simulate[@check_attacker[0]][@check_attacker[1]] = w_rook
          @board_simulate[index/8][index%8] = empty
          return true if king_in_danger == false
        end
      end

      # Takedown from a bishop?
      restore_board_color
      @board_simulate = @board.clone.map(&:clone)
      b_bishop_moveset(@check_attacker[0], @check_attacker[1])
      @color.flatten.each_with_index do | item, index | 
        if item == 41 && @board_simulate.flatten[index] == w_bishop
          @board_simulate[@check_attacker[0]][@check_attacker[1]] = w_bishop
          @board_simulate[index/8][index%8] = empty
          return true if king_in_danger == false
        end
      end

      # Takedown from a queen?
      restore_board_color
      @board_simulate = @board.clone.map(&:clone)
      b_rook_moveset(@check_attacker[0], @check_attacker[1])
      b_bishop_moveset(@check_attacker[0], @check_attacker[1])
      @color.flatten.each_with_index do | item, index | 
        if item == 41 && @board_simulate.flatten[index] == w_queen
          @board_simulate[@check_attacker[0]][@check_attacker[1]] = w_queen
          @board_simulate[index/8][index%8] = empty
          return true if king_in_danger == false
        end
      end

      # Takedown from a knight?
      restore_board_color
      @board_simulate = @board.clone.map(&:clone)
      b_knight_moveset(@check_attacker[0], @check_attacker[1])
      @color.flatten.each_with_index do | item, index | 
        if item == 41 && @board_simulate.flatten[index] == w_knight
          @board_simulate[@check_attacker[0]][@check_attacker[1]] = w_knight
          @board_simulate[index/8][index%8] = empty
          return true if king_in_danger == false
        end
      end

    end # End of Black attacker

    # Can enemy white piece be taken down?
    if white_pieces.any?(@check_attacker[2])

      # Takedown from a pawn?
      restore_board_color
      @board_simulate = @board.clone.map(&:clone)
      w_pawn_moveset(@check_attacker[0], @check_attacker[1])
      @color.flatten.each_with_index do | item, index | 
        if item == 41 && @board_simulate.flatten[index] == b_pawn
          @board_simulate[@check_attacker[0]][@check_attacker[1]] = b_pawn
          @board_simulate[index/8][index%8] = empty
          return true if king_in_danger == false
        end
      end

      # Takedown from a rook?
      restore_board_color
      @board_simulate = @board.clone.map(&:clone)
      w_rook_moveset(@check_attacker[0], @check_attacker[1])
      @color.flatten.each_with_index do | item, index | 
        if item == 41 && @board_simulate.flatten[index] == b_rook
          @board_simulate[@check_attacker[0]][@check_attacker[1]] = b_rook
          @board_simulate[index/8][index%8] = empty
          return true if king_in_danger == false
        end
      end

      # Takedown from a bishop?
      restore_board_color
      @board_simulate = @board.clone.map(&:clone)
      w_bishop_moveset(@check_attacker[0], @check_attacker[1])
      @color.flatten.each_with_index do | item, index | 
        if item == 41 && @board_simulate.flatten[index] == b_bishop
          @board_simulate[@check_attacker[0]][@check_attacker[1]] = b_bishop
          @board_simulate[index/8][index%8] = empty
          return true if king_in_danger == false
        end
      end

      # Takedown from a queen?
      restore_board_color
      @board_simulate = @board.clone.map(&:clone)
      w_rook_moveset(@check_attacker[0], @check_attacker[1])
      w_bishop_moveset(@check_attacker[0], @check_attacker[1])
      @color.flatten.each_with_index do | item, index | 
        if item == 41 && @board_simulate.flatten[index] == b_queen
          @board_simulate[@check_attacker[0]][@check_attacker[1]] = b_queen
          @board_simulate[index/8][index%8] = empty
          return true if king_in_danger == false
        end
      end

      # Takedown from a knight?
      restore_board_color
      @board_simulate = @board.clone.map(&:clone)
      w_knight_moveset(@check_attacker[0], @check_attacker[1])
      @color.flatten.each_with_index do | item, index | 
        if item == 41 && @board_simulate.flatten[index] == b_knight
          @board_simulate[@check_attacker[0]][@check_attacker[1]] = b_knight
          @board_simulate[index/8][index%8] = empty
          return true if king_in_danger == false
        end
      end

    end # End of white attacker

    false
  end

  def king_in_danger

    # Assess if White king is in danger by any black piece
    if @current == "Black"
      restore_board_color
      w_pawn_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == b_pawn }

      restore_board_color
      w_knight_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == b_knight }

      restore_board_color
      w_rook_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == b_rook }

      restore_board_color
      w_bishop_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == b_bishop }

      restore_board_color
      w_bishop_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      w_rook_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == b_queen }

    end

    # Assess if Black king is in danger by any white piece
    if @current == "White"
      restore_board_color
      b_pawn_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == w_pawn }

      restore_board_color
      b_knight_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == w_knight }

      restore_board_color
      b_rook_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == w_rook }

      restore_board_color
      b_bishop_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == w_bishop }

      restore_board_color
      b_bishop_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      b_rook_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == w_queen }

    end

    false
  end

  def i_king_in_danger
    # Same is king_in_danger but with different comparison for @current
    # This is used to see if current player's move will make him open for a check

    # Assess if White king is open to a check
    if @current == "White"
      restore_board_color
      w_pawn_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == b_pawn }

      restore_board_color
      w_knight_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == b_knight }

      restore_board_color
      w_rook_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == b_rook }

      restore_board_color
      w_bishop_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == b_bishop }

      restore_board_color
      w_bishop_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      w_rook_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == b_queen }

      restore_board_color
      w_king_moveset(@sim_w_king_pos[0], @sim_w_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == b_king }

    end

    # Assess if Black king is open to a check
    if @current == "Black"
      restore_board_color
      b_pawn_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == w_pawn }

      restore_board_color
      b_knight_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == w_knight }

      restore_board_color
      b_rook_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == w_rook }

      restore_board_color
      b_bishop_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == w_bishop }

      restore_board_color
      b_bishop_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      b_rook_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == w_queen }

      restore_board_color
      b_king_moveset(@sim_b_king_pos[0], @sim_b_king_pos[1])
      @color.flatten.each_with_index { | item, index | return true if item == 41 && @board_simulate.flatten[index] == w_king }

    end

    false
  end

  def simulation_off
    @simulation = false
  end

  def b_king_moveset(row,column)
    board = []
    @simulation == true ? board = @board_simulate.clone.map(&:clone) : board = @board.clone.map(&:clone)

    if (column+1).between?(0,7)
      @color[row][column+1] = 41 if @board[row][column+1] == empty || white_pieces.any?(@board[row][column+1])
      if (row+1).between?(0,7)
        @color[row+1][column+1] = 41 if @board[row+1][column+1] == empty || white_pieces.any?(@board[row+1][column+1])
      end
      if (row-1).between?(0,7)
        @color[row-1][column+1] = 41 if @board[row-1][column+1] == empty || white_pieces.any?(@board[row-1][column+1])
      end
    end
    if (column-1).between?(0,7)
      @color[row][column-1] = 41 if @board[row][column-1] == empty || white_pieces.any?(@board[row][column-1])
      if (row+1).between?(0,7)
        @color[row+1][column-1] = 41 if @board[row+1][column-1] == empty || white_pieces.any?(@board[row+1][column-1])
      end
      if (row-1).between?(0,7)
        @color[row-1][column-1] = 41 if @board[row-1][column-1] == empty || white_pieces.any?(@board[row-1][column-1])
      end
    end
    if (row+1).between?(0,7)
      @color[row+1][column] = 41 if @board[row+1][column] == empty || white_pieces.any?(@board[row+1][column])
    end
    if (row-1).between?(0,7)
      @color[row-1][column] = 41 if @board[row-1][column] == empty || white_pieces.any?(@board[row-1][column])
    end
  end

  def w_king_moveset(row,column)
    board = []
    @simulation == true ? board = @board_simulate.clone.map(&:clone) : board = @board.clone.map(&:clone)

    if (column+1).between?(0,7)
      @color[row][column+1] = 41 if @board[row][column+1] == empty || black_pieces.any?(@board[row][column+1])
      if (row+1).between?(0,7)
        @color[row+1][column+1] = 41 if @board[row+1][column+1] == empty || black_pieces.any?(@board[row+1][column+1])
      end
      if (row-1).between?(0,7)
        @color[row-1][column+1] = 41 if @board[row-1][column+1] == empty || black_pieces.any?(@board[row-1][column+1])
      end
    end
    if (column-1).between?(0,7)
      @color[row][column-1] = 41 if @board[row][column-1] == empty || black_pieces.any?(@board[row][column-1])
      if (row+1).between?(0,7)
        @color[row+1][column-1] = 41 if @board[row+1][column-1] == empty || black_pieces.any?(@board[row+1][column-1])
      end
      if (row-1).between?(0,7)
        @color[row-1][column-1] = 41 if @board[row-1][column-1] == empty || black_pieces.any?(@board[row-1][column-1])
      end
    end
    if (row+1).between?(0,7)
      @color[row+1][column] = 41 if @board[row+1][column] == empty || black_pieces.any?(@board[row+1][column])
    end
    if (row-1).between?(0,7)
      @color[row-1][column] = 41 if @board[row-1][column] == empty || black_pieces.any?(@board[row-1][column])
    end
  end

  def stalemate_criteria

    # King vs king
    @stalemate = true if @board.flatten.count(empty) == 62

    # Black king vs White bishop and White King
    @stalemate = true if @board.flatten.count(empty) == 61 && @board.flatten.count(w_bishop) == 1

    # White king vs Black bishop and black King
    @stalemate = true if @board.flatten.count(empty) == 61 && @board.flatten.count(b_bishop) == 1

    # Black king vs White knight/s and White King
    @stalemate = true if @board.flatten.count(empty) == 60 && @board.flatten.count(w_knight) == 2
    @stalemate = true if @board.flatten.count(empty) == 61 && @board.flatten.count(w_knight) == 1

    # White king vs Black knight/s and White King
    @stalemate = true if @board.flatten.count(empty) == 60 && @board.flatten.count(b_knight) == 2
    @stalemate = true if @board.flatten.count(empty) == 61 && @board.flatten.count(b_knight) == 1

    # 50 moves but no progress
    @stalemate = true if @end_game_timer == 0
    

  end

  def save
    data = {

      board: @board,
      en_passant: @en_passant,
      en_passant_turn: @en_passant_turn,

      promotion: @promotion,
      pawn_color: @pawn_color,

      b_castling: @b_castling,
      w_castling: @w_castling,

      eliminated: @eliminated,

      check: @check,
      king_in_check: @king_in_check,
      check_attacker: @check_attacker,
      current: @current,

      checkmate: @checkmate,
      stalemate: @stalemate,
      b_king_pos: @b_king_pos,
      w_king_pos: @w_king_pos,
      current_piece: @current_piece,
      board_simulate: @board_simulate,

      sim_b_king_pos: @sim_b_king_pos,
      sim_w_king_pos: @sim_w_king_pos,

      simulation: @simulation,
      end_game_timer: @end_game_timer

    }
    file = File.open("lib/save_board.yaml","w")
    file.puts YAML.dump(data)
    file.close
  end

  def load
    begin
      data = YAML.load(File.open("lib/save_board.yaml", "r").read)

      @board = data[:board]
      @en_passant = data[:en_passant]
      @en_passant_turn = data[:en_passant_turn]

      @promotion = data[:promotion]
      @pawn_color = data[:pawn_color]

      @b_castling = data[:b_castling]
      @w_castling = data[:w_castling]

      @eliminated = data[:eliminated]

      @check = data[:check]
      @king_in_check = data[:king_in_check]
      @check_attacker = data[:check_attacker]
      @current = data[:current]

      @checkmate = data[:checkmate]
      @stalemate = data[:stalemate]
      @b_king_pos = data[:b_king_pos]
      @w_king_pos = data[:w_king_pos]
      @current_piece = data[:current_piece]
      @board_simulate = data[:board_simulate]

      @sim_b_king_pos = data[:sim_b_king_pos]
      @sim_w_king_pos  = data[:sim_w_king_pos]

      @simulation = data[:simulation]
      @end_game_timer = data[:end_game_timer]

    rescue StandardError
      nil
    end
  end


end # End of board class!
