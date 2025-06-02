# frozen_string_literal: true

require_relative "RubyChess/version"

module RubyChess
  class Error < StandardError; end
  # Your code goes here...

   class ChessEngine
  
  # Инициализация доски
  def initialize
    @board = create_initial_board
    @current_player = :white
    @game_over = false
    @move_history = []
  end

  # Основной игровой цикл
  def play
    until @game_over
      display_board
      puts "#{@current_player.capitalize}'s turn. Enter your move ('e2 e4' or 'O-O' for castling or 'O-O-O' for large castling):"
      input = gets.chomp
      
      if input.downcase == 'quit'
        @game_over = true
        next
      end
      
      if valid_input?(input)
        if process_move(input)
          switch_player
          check_game_status
        else
          puts "Invalid move. Try again."
        end
      else
        puts "Invalid input format. Please use standard chess notation ('e2 e4' or 'O-O' for castling or 'O-O-O' for large castling)."
      end
    end
  end

  private

  # Создание начальной позиции
  def create_initial_board
    board = Array.new(8) { Array.new(8, nil) }
    
    # Расставляем пешки
    8.times do |i|
      board[1][i] = { type: :pawn, color: :black, moved: false }
      board[6][i] = { type: :pawn, color: :white, moved: false }
    end
    
    # Расставляем остальные фигуры
    pieces_order = [:rook, :knight, :bishop, :queen, :king, :bishop, :knight, :rook]
    
    pieces_order.each_with_index do |piece, i|
      board[0][i] = { type: piece, color: :black, moved: false }
      board[7][i] = { type: piece, color: :white, moved: false }
    end
    
    board
  end

  # Отображение доски в консоли
  def display_board
    puts "\n   a  b  c  d  e  f  g  h"
    puts "  -------------------------"
    
    @board.each_with_index do |row, i|
      print "#{8 - i} |"
      row.each do |square|
        if square.nil?
          print "  |"
        else
          piece_char = case square[:type]
                       when :king then square[:color] == :white ? '♚' : '♔'
                       when :queen then square[:color] == :white ? '♛' : '♕'
                       when :rook then square[:color] == :white ? '♜' : '♖'
                       when :bishop then square[:color] == :white ? '♝' : '♗'
                       when :knight then square[:color] == :white ? '♞' : '♘'
                       when :pawn then square[:color] == :white ? '♟' : '♙'
                       end
          print "#{piece_char} |"
        end
      end
      puts "\n  -------------------------"
    end
    puts
  end

  # Проверка формата ввода
  def valid_input?(input)
    # Проверка обычного хода (e2 e4)
    return true if input.match(/^[a-h][1-8]\s[a-h][1-8]$/)
    
    # Проверка рокировки
    return true if input.match(/^O-O(-O)?$/i)
    
    false
  end

  # Обработка хода
  def process_move(input)
    if input.match(/^O-O(-O)?$/i)
      # Рокировка
      castle_type = input.include?('-O-O') ? :queenside : :kingside
      return castle(castle_type)
    else
      # Обычный ход
      from, to = input.split
      from_pos = notation_to_position(from)
      to_pos = notation_to_position(to)
      
      return false unless valid_move?(from_pos, to_pos)
      
      # Выполняем ход
      move_piece(from_pos, to_pos)
      true
    end
  end

  # Преобразование шахматной нотации в координаты массива
  def notation_to_position(notation)
    col = notation[0].downcase.ord - 'a'.ord
    row = 8 - notation[1].to_i
    [row, col]
  end

  # Проверка допустимости хода
  def valid_move?(from_pos, to_pos)
    from_row, from_col = from_pos
    to_row, to_col = to_pos
    
    # Проверка на выход за пределы доски
    return false unless (0..7).cover?(from_row) && (0..7).cover?(from_col)
    return false unless (0..7).cover?(to_row) && (0..7).cover?(to_col)
    
    piece = @board[from_row][from_col]
    
    # Проверка, что фигура существует и принадлежит текущему игроку
    return false if piece.nil? || piece[:color] != @current_player
    
    target = @board[to_row][to_col]
    
    # Проверка, что целевая клетка либо пуста, либо занята фигурой противника
    return false unless target.nil? || target[:color] != @current_player
    
    # Базовая проверка правил движения для каждой фигуры
    case piece[:type]
    when :pawn
      return valid_pawn_move?(from_pos, to_pos, piece[:color])
    when :knight
      return valid_knight_move?(from_pos, to_pos)
    when :bishop
      return valid_bishop_move?(from_pos, to_pos)
    when :rook
      return valid_rook_move?(from_pos, to_pos)
    when :queen
      return valid_queen_move?(from_pos, to_pos)
    when :king
      return valid_king_move?(from_pos, to_pos)
    end
    
    false
  end

  # Проверка хода пешки
  def valid_pawn_move?(from_pos, to_pos, color)
    from_row, from_col = from_pos
    to_row, to_col = to_pos
    
    direction = color == :white ? -1 : 1
    start_row = color == :white ? 6 : 1
    
    # Обычный ход на одну клетку
    if from_col == to_col && @board[to_row][to_col].nil?
      return true if to_row == from_row + direction
      
      # Ход на две клетки из начальной позиции
      if from_row == start_row && to_row == from_row + 2 * direction
        return @board[from_row + direction][from_col].nil? # Проверка, что путь свободен
      end
    end
    
    # Взятие фигуры по диагонали
    if (to_col == from_col + 1 || to_col == from_col - 1) && 
       to_row == from_row + direction && 
       !@board[to_row][to_col].nil? && 
       @board[to_row][to_col][:color] != color
      return true
    end
    
    false
  end

  # Проверка хода коня
  def valid_knight_move?(from_pos, to_pos)
    from_row, from_col = from_pos
    to_row, to_col = to_pos
    
    dx = (to_col - from_col).abs
    dy = (to_row - from_row).abs
    
    (dx == 1 && dy == 2) || (dx == 2 && dy == 1)
  end

  # Проверка хода слона
  def valid_bishop_move?(from_pos, to_pos)
    from_row, from_col = from_pos
    to_row, to_col = to_pos
    
    # Движение должно быть по диагонали
    return false unless (to_col - from_col).abs == (to_row - from_row).abs
    
    # Проверка, что путь свободен
    row_step = to_row > from_row ? 1 : -1
    col_step = to_col > from_col ? 1 : -1
    
    row, col = from_row + row_step, from_col + col_step
    
    while row != to_row && col != to_col
      return false unless @board[row][col].nil?
      row += row_step
      col += col_step
    end
    
    true
  end

  # Проверка хода ладьи
  def valid_rook_move?(from_pos, to_pos)
    from_row, from_col = from_pos
    to_row, to_col = to_pos
    
    # Движение должно быть по вертикали или горизонтали
    return false unless from_row == to_row || from_col == to_col
    
    # Проверка, что путь свободен
    if from_row == to_row
      step = to_col > from_col ? 1 : -1
      col = from_col + step
      while col != to_col
        return false unless @board[from_row][col].nil?
        col += step
      end
    else
      step = to_row > from_row ? 1 : -1
      row = from_row + step
      while row != to_row
        return false unless @board[row][from_col].nil?
        row += step
      end
    end
    
    true
  end

  # Проверка хода ферзя
  def valid_queen_move?(from_pos, to_pos)
    valid_bishop_move?(from_pos, to_pos) || valid_rook_move?(from_pos, to_pos)
  end

  # Проверка хода короля
  def valid_king_move?(from_pos, to_pos)
    from_row, from_col = from_pos
    to_row, to_col = to_pos
    
    dx = (to_col - from_col).abs
    dy = (to_row - from_row).abs
    
    # Обычный ход на одну клетку в любом направлении
    dx <= 1 && dy <= 1
  end

  # Выполнение рокировки  ДАНЬКОВИЧ!!!
  def castle(type)
    row = @current_player == :white ? 7 : 0
    king_col = 4
    rook_col = type == :kingside ? 7 : 0
    new_king_col = type == :kingside ? 6 : 2
    new_rook_col = type == :kingside ? 5 : 3
    
    king = @board[row][king_col]
    rook = @board[row][rook_col]
    
    # Проверка условий для рокировки
    return false if king.nil? || rook.nil?
    return false unless king[:type] == :king && rook[:type] == :rook
    return false if king[:moved] || rook[:moved]
    
    # Проверка, что путь свободен
    if type == :kingside
      return false unless @board[row][5].nil? && @board[row][6].nil?
    else
      return false unless @board[row][1].nil? && @board[row][2].nil? && @board[row][3].nil?
    end
    
    # Проверка, что король не под шахом и не проходит через атакованные клетки
    # (это упрощенная версия, в реальной игре нужно проверять шах)
    
    # Выполняем рокировку
    @board[row][king_col] = nil
    @board[row][rook_col] = nil
    @board[row][new_king_col] = { type: :king, color: @current_player, moved: true }
    @board[row][new_rook_col] = { type: :rook, color: @current_player, moved: true }
    
    true
  end

   # Смена игрока
  def switch_player
    @current_player = @current_player == :white ? :black : :white
  end

  # Перемещение фигуры
  def move_piece(from_pos, to_pos)
    from_row, from_col = from_pos
    to_row, to_col = to_pos
    
    piece = @board[from_row][from_col]
    piece[:moved] = true if piece[:type] == :king || piece[:type] == :rook
    
    @board[to_row][to_col] = piece
    @board[from_row][from_col] = nil
    
    # Превращение пешки
    if piece[:type] == :pawn && (to_row == 0 || to_row == 7)
      promote_pawn(to_pos)
    end
    
    @move_history << { from: from_pos, to: to_pos, piece: piece }
  end

   # Проверка, был ли король захвачен (упрощенная проверка на мат) ДАНЬКОВИЧ!!!
  def king_captured?
    king_found = { white: false, black: false }
    
    @board.each do |row|
      row.each do |piece|
        next if piece.nil?
        
        if piece[:type] == :king
          king_found[piece[:color]] = true
        end
      end
    end
    
    !king_found[:white] || !king_found[:black]
  end

  # Превращение пешки
  def promote_pawn(pos)
    row, col = pos
    puts "Pawn promotion! Choose a piece (Q/R/B/N):"
    input = gets.chomp.upcase
    
    piece_type = case input
                 when 'Q' then :queen
                 when 'R' then :rook
                 when 'B' then :bishop
                 when 'N' then :knight
                 else :queen # По умолчанию ферзь
                 end
    
    @board[row][col][:type] = piece_type
  end

 

  # Проверка статуса игры (мат, пат, шах) ДАНЬКОВИЧ!!!
  def check_game_status
    # проверка только на cъедание короля 
    if king_captured?
      @game_over = true
      display_board
      puts "Game over! #{@current_player.capitalize} wins by capturing the king!"
    end
  end

 
end

# Запуск игры
puts "Welcome to Ruby Chess!"
puts "Enter moves in standard notation ('e2 e4' or 'O-O' for castling or 'O-O-O' for large castling)"
puts "Type 'quit' to exit the game."

game = ChessEngine.new
game.play

end
