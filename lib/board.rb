# frozen_string_literal: true

# Color cheat sheet:
#   bg_black    40
#   bg_red      41 --> Viable move
#   bg_green    42 --> Current piece
#   bg_brown    43
#   bg_blue     44 --> Dark color
#   bg_magenta  45 --> En passant capture
#   bg_cyan     46
#   bg_gray     47

require_relative "symbols"

class Board
  include Symbols

  def initialize
    #@board = [[],[],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"], ["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"], ["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],[],[]]
    @board = [["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"], ["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"], ["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"],["#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}","#{empty}"]]
    
    #@board[0] = ["#{w_rook}","#{w_knight}","#{w_bishop}","#{w_queen}","#{w_king}","#{w_bishop}","#{w_knight}","#{w_rook}"]
    @board[1] = ["#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}","#{w_pawn}"]
    @board[6] = ["#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}","#{b_pawn}"]
    #@board[7] = ["#{b_rook}","#{b_knight}","#{b_bishop}","#{b_queen}","#{b_king}","#{b_bishop}","#{b_knight}","#{b_rook}"]
    @dark = 44
    @light = 1
    @color = [[@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark], [@dark,@light,@dark,@light,@dark,@light,@dark,@light], [@light,@dark,@light,@dark,@light,@dark,@light,@dark]]

    @en_passant = []
    @en_passant_turn = 0

    @promotion = false
    @pawn_color = nil
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
      
      if @board[row-1][column] == empty
        @color[row-1][column] = 41
      end
      if (column+1).between?(0,7)
        @color[row-1][column+1] = 41 if white_pieces.any?(@board[row-1][column+1])
      end
      if (column-1).between?(0,7)
        @color[row-1][column-1] = 41 if white_pieces.any?(@board[row-1][column-1])
      end

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
      
      if @board[row+1][column] == empty
        @color[row+1][column] = 41
      end
      if (column+1).between?(0,7)
        @color[row+1][column+1] = 41 if black_pieces.any?(@board[row+1][column+1])
      end
      if (column-1).between?(0,7)
        @color[row+1][column-1] = 41 if black_pieces.any?(@board[row+1][column-1])
      end

      # En-passant attack
      if @en_passant_turn > 0
        if @en_passant.length >= 3
          @color[row+1][@en_passant[0]] = 45 if @board[row][column] == @board[row][@en_passant[2]]
        end
        if @en_passant.length >=2
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


    #when b_king || w_king
    #when b_queen || w_queen
    #when b_knight || w_knight
    #when b_bishop || w_bishop
    # when b_rook
    #   return true if @board[row][column+1] == empty || white_pieces.any?(@board[row][column+1])
    #   return true if @board[row+1][column] == empty || white_pieces.any?(@board[row+1][column])
    #   return true if @board[row][column-1] == empty || white_pieces.any?(@board[row][column-1])
    #   return true if @board[row-1][column] == empty || white_pieces.any?(@board[row-1][column])
    #   false
    # when w_rook
    #   return true if @board[row][column+1] == empty || black_pieces.any?(@board[row][column+1])
    #   return true if @board[row+1][column] == empty || black_pieces.any?(@board[row+1][column])
    #   return true if @board[row][column-1] == empty || black_pieces.any?(@board[row][column-1])
    #   return true if @board[row-1][column] == empty || black_pieces.any?(@board[row-1][column])
    #   return false




    end # end of case
  
    @en_passant_turn -= 1
    true
  end # end of valid moves!

  def color_origin(coordinates)
    row     = coordinates[0]
    column  = coordinates[1]
    @color[row][column] = 42
  





    # case piece
      #when b_king || w_king
      #when b_queen || w_queen
      #when b_knight || w_knight
      #when b_bishop || w_bishop
      # when b_rook
      #   for tile in 1..7 
      #     break if column+tile > 7
      #     break if black_pieces.any?(@board[row][column+tile])
      #     @color[row][column+tile] = 41
      #     break if white_pieces.any?(@board[row][column+tile])
      #   end
      #   for tile in 1..7 
      #     break if row+tile > 7
      #     break if black_pieces.any?(@board[row+tile][column])
      #     @color[row][column+tile] = 41
      #     break if white_pieces.any?(@board[row+tile][column])
      #   end
      #   for tile in 1..7 
      #     break if column-tile < 0
      #     break if black_pieces.any?(@board[row][column-tile])
      #     @color[row][column+tile] = 41
      #     break if white_pieces.any?(@board[row][column-tile])
      #   end
      #   for tile in 1..7 
      #     break if row-tile < 0
      #     break if black_pieces.any?(@board[row-tile][column])
      #     @color[row][column+tile] = 41
      #     break if white_pieces.any?(@board[row-tile][column])
      #   end


      # when w_rook
      #   for tile in 1..7 
      #     break if column+tile > 7
      #     break if white_pieces.any?(@board[row][column+tile])
      #     @color[row][column+tile] = 41
      #     break if black_pieces.any?(@board[row][column+tile])
      #   end
      #   for tile in 1..7 
      #     break if row+tile > 7
      #     break if white_pieces.any?(@board[row+tile][column])
      #     @color[row][column+tile] = 41
      #     break if black_pieces.any?(@board[row+tile][column])
      #   end
      #   for tile in 1..7 
      #     break if column-tile < 0
      #     break if white_pieces.any?(@board[row][column-tile])
      #     @color[row][column+tile] = 41
      #     break if black_pieces.any?(@board[row][column-tile])
      #   end
      #   for tile in 1..7 
      #     break if row-tile < 0
      #     break if white_pieces.any?(@board[row-tile][column])
      #     @color[row][column+tile] = 41
      #     break if black_pieces.any?(@board[row-tile][column])
      #   end
  
  end # end of color moves


  def valid_area?(row, column)
    return true if @color[row][column] == 41
    return "en-passant" if @color[row][column] == 45
    false
  end

  def move_piece(coordinates)
    # Get row and column values of origin and target move
    row_orig = coordinates[0]
    col_orig = coordinates[1]
    row_move = coordinates[2]
    col_move = coordinates[3]
    
    # Moving piece occupies the new tile and leaves an empty tile behind
    @board[row_move][col_move] = @board[row_orig][col_orig]
    @board[row_orig][col_orig] = empty

    # Eliminate en-passant piece
    @board[row_orig][col_move] = empty if coordinates[4] == "en-passant"

    # Pawn promotion
    pawn_promotion(row_move, col_move) if @promotion == true
    @promotion = false

    # Restore board color
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


end # End of board class!
