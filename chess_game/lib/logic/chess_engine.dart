import '../models/chess_piece.dart';
import '../models/chess_move.dart';

class ChessEngine {
  List<List<ChessPiece?>> board = [];
  PieceColor currentTurn = PieceColor.white;
  List<ChessMove> moveHistory = [];
  int? enPassantTargetRow;
  int? enPassantTargetCol;
  bool whiteKingSideCastle = true;
  bool whiteQueenSideCastle = true;
  bool blackKingSideCastle = true;
  bool blackQueenSideCastle = true;

  ChessEngine() {
    resetBoard();
  }

  void resetBoard() {
    board = List.generate(8, (_) => List<ChessPiece?>.filled(8, null));
    currentTurn = PieceColor.white;
    moveHistory = [];
    enPassantTargetRow = null;
    enPassantTargetCol = null;
    whiteKingSideCastle = true;
    whiteQueenSideCastle = true;
    blackKingSideCastle = true;
    blackQueenSideCastle = true;

    // Place pawns
    for (int col = 0; col < 8; col++) {
      board[1][col] = ChessPiece(type: PieceType.pawn, color: PieceColor.black);
      board[6][col] = ChessPiece(type: PieceType.pawn, color: PieceColor.white);
    }

    // Place back rows
    final backRow = [
      PieceType.rook, PieceType.knight, PieceType.bishop, PieceType.queen,
      PieceType.king, PieceType.bishop, PieceType.knight, PieceType.rook
    ];
    for (int col = 0; col < 8; col++) {
      board[0][col] = ChessPiece(type: backRow[col], color: PieceColor.black);
      board[7][col] = ChessPiece(type: backRow[col], color: PieceColor.white);
    }
  }

  ChessEngine copy() {
    final engine = ChessEngine();
    engine.board = List.generate(8, (r) => 
      List.generate(8, (c) => board[r][c]?.copyWith()));
    engine.currentTurn = currentTurn;
    engine.moveHistory = List.from(moveHistory);
    engine.enPassantTargetRow = enPassantTargetRow;
    engine.enPassantTargetCol = enPassantTargetCol;
    engine.whiteKingSideCastle = whiteKingSideCastle;
    engine.whiteQueenSideCastle = whiteQueenSideCastle;
    engine.blackKingSideCastle = blackKingSideCastle;
    engine.blackQueenSideCastle = blackQueenSideCastle;
    return engine;
  }

  bool isValidPosition(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  List<List<int>> getValidMoves(int row, int col) {
    final piece = board[row][col];
    if (piece == null) return [];
    if (piece.color != currentTurn) return [];

    List<List<int>> moves = [];

    switch (piece.type) {
      case PieceType.pawn:
        moves = _getPawnMoves(row, col, piece);
        break;
      case PieceType.rook:
        moves = _getRookMoves(row, col, piece);
        break;
      case PieceType.knight:
        moves = _getKnightMoves(row, col, piece);
        break;
      case PieceType.bishop:
        moves = _getBishopMoves(row, col, piece);
        break;
      case PieceType.queen:
        moves = [..._getRookMoves(row, col, piece), ..._getBishopMoves(row, col, piece)];
        break;
      case PieceType.king:
        moves = _getKingMoves(row, col, piece);
        break;
    }

    // Filter moves that would leave king in check
    moves = moves.where((move) {
      final testEngine = copy();
      testEngine._makeMoveWithoutValidation(row, col, move[0], move[1]);
      return !testEngine.isKingInCheck(piece.color);
    }).toList();

    return moves;
  }

  List<List<int>> _getPawnMoves(int row, int col, ChessPiece piece) {
    List<List<int>> moves = [];
    int direction = piece.color == PieceColor.white ? -1 : 1;
    int startRow = piece.color == PieceColor.white ? 6 : 1;

    // Forward one
    if (isValidPosition(row + direction, col) && board[row + direction][col] == null) {
      moves.add([row + direction, col]);
      // Forward two from start
      if (row == startRow && board[row + 2 * direction][col] == null) {
        moves.add([row + 2 * direction, col]);
      }
    }

    // Captures
    for (int dc in [-1, 1]) {
      int newCol = col + dc;
      if (isValidPosition(row + direction, newCol)) {
        // Normal capture
        if (board[row + direction][newCol] != null && 
            board[row + direction][newCol]!.color != piece.color) {
          moves.add([row + direction, newCol]);
        }
        // En passant
        if (enPassantTargetRow == row + direction && enPassantTargetCol == newCol) {
          moves.add([row + direction, newCol]);
        }
      }
    }

    return moves;
  }

  List<List<int>> _getRookMoves(int row, int col, ChessPiece piece) {
    List<List<int>> moves = [];
    final directions = [[-1, 0], [1, 0], [0, -1], [0, 1]];
    for (var dir in directions) {
      for (int i = 1; i < 8; i++) {
        int newRow = row + dir[0] * i;
        int newCol = col + dir[1] * i;
        if (!isValidPosition(newRow, newCol)) break;
        if (board[newRow][newCol] == null) {
          moves.add([newRow, newCol]);
        } else {
          if (board[newRow][newCol]!.color != piece.color) {
            moves.add([newRow, newCol]);
          }
          break;
        }
      }
    }
    return moves;
  }

  List<List<int>> _getKnightMoves(int row, int col, ChessPiece piece) {
    List<List<int>> moves = [];
    final jumps = [[-2, -1], [-2, 1], [-1, -2], [-1, 2], [1, -2], [1, 2], [2, -1], [2, 1]];
    for (var jump in jumps) {
      int newRow = row + jump[0];
      int newCol = col + jump[1];
      if (isValidPosition(newRow, newCol)) {
        if (board[newRow][newCol] == null || board[newRow][newCol]!.color != piece.color) {
          moves.add([newRow, newCol]);
        }
      }
    }
    return moves;
  }

  List<List<int>> _getBishopMoves(int row, int col, ChessPiece piece) {
    List<List<int>> moves = [];
    final directions = [[-1, -1], [-1, 1], [1, -1], [1, 1]];
    for (var dir in directions) {
      for (int i = 1; i < 8; i++) {
        int newRow = row + dir[0] * i;
        int newCol = col + dir[1] * i;
        if (!isValidPosition(newRow, newCol)) break;
        if (board[newRow][newCol] == null) {
          moves.add([newRow, newCol]);
        } else {
          if (board[newRow][newCol]!.color != piece.color) {
            moves.add([newRow, newCol]);
          }
          break;
        }
      }
    }
    return moves;
  }

  List<List<int>> _getKingMoves(int row, int col, ChessPiece piece) {
    List<List<int>> moves = [];
    final directions = [[-1, -1], [-1, 0], [-1, 1], [0, -1], [0, 1], [1, -1], [1, 0], [1, 1]];
    for (var dir in directions) {
      int newRow = row + dir[0];
      int newCol = col + dir[1];
      if (isValidPosition(newRow, newCol)) {
        if (board[newRow][newCol] == null || board[newRow][newCol]!.color != piece.color) {
          moves.add([newRow, newCol]);
        }
      }
    }

    // Castling
    if (!piece.hasMoved && !isKingInCheck(piece.color)) {
      bool kingSide = piece.color == PieceColor.white ? whiteKingSideCastle : blackKingSideCastle;
      bool queenSide = piece.color == PieceColor.white ? whiteQueenSideCastle : blackQueenSideCastle;

      // King side
      if (kingSide && board[row][5] == null && board[row][6] == null) {
        final rook = board[row][7];
        if (rook != null && rook.type == PieceType.rook && !rook.hasMoved) {
          if (!_isSquareAttacked(row, 5, piece.color) && !_isSquareAttacked(row, 6, piece.color)) {
            moves.add([row, 6]);
          }
        }
      }

      // Queen side
      if (queenSide && board[row][1] == null && board[row][2] == null && board[row][3] == null) {
        final rook = board[row][0];
        if (rook != null && rook.type == PieceType.rook && !rook.hasMoved) {
          if (!_isSquareAttacked(row, 2, piece.color) && !_isSquareAttacked(row, 3, piece.color)) {
            moves.add([row, 2]);
          }
        }
      }
    }

    return moves;
  }

  bool _isSquareAttacked(int row, int col, PieceColor defendingColor) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece != null && piece.color != defendingColor) {
          if (_canAttackSquare(r, c, row, col, piece)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _canAttackSquare(int fromRow, int fromCol, int toRow, int toCol, ChessPiece piece) {
    switch (piece.type) {
      case PieceType.pawn:
        int direction = piece.color == PieceColor.white ? -1 : 1;
        return toRow == fromRow + direction && (toCol == fromCol - 1 || toCol == fromCol + 1);
      case PieceType.knight:
        int dr = (toRow - fromRow).abs();
        int dc = (toCol - fromCol).abs();
        return dr * dc == 2 && dr + dc == 3;
      case PieceType.king:
        return (toRow - fromRow).abs() <= 1 && (toCol - fromCol).abs() <= 1;
      case PieceType.rook:
        return _isStraightLine(fromRow, fromCol, toRow, toCol) && _isPathClear(fromRow, fromCol, toRow, toCol);
      case PieceType.bishop:
        return _isDiagonal(fromRow, fromCol, toRow, toCol) && _isPathClear(fromRow, fromCol, toRow, toCol);
      case PieceType.queen:
        return (_isStraightLine(fromRow, fromCol, toRow, toCol) || _isDiagonal(fromRow, fromCol, toRow, toCol))
            && _isPathClear(fromRow, fromCol, toRow, toCol);
    }
  }

  bool _isStraightLine(int r1, int c1, int r2, int c2) {
    return r1 == r2 || c1 == c2;
  }

  bool _isDiagonal(int r1, int c1, int r2, int c2) {
    return (r1 - r2).abs() == (c1 - c2).abs();
  }

  bool _isPathClear(int r1, int c1, int r2, int c2) {
    int dr = (r2 - r1).sign;
    int dc = (c2 - c1).sign;
    int r = r1 + dr;
    int c = c1 + dc;
    while (r != r2 || c != c2) {
      if (board[r][c] != null) return false;
      r += dr;
      c += dc;
    }
    return true;
  }

  bool isKingInCheck(PieceColor color) {
    int kingRow = -1, kingCol = -1;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece != null && piece.type == PieceType.king && piece.color == color) {
          kingRow = r;
          kingCol = c;
          break;
        }
      }
      if (kingRow != -1) break;
    }
    return _isSquareAttacked(kingRow, kingCol, color);
  }

  bool isCheckmate() {
    if (!isKingInCheck(currentTurn)) return false;
    return _hasNoLegalMoves();
  }

  bool isStalemate() {
    if (isKingInCheck(currentTurn)) return false;
    return _hasNoLegalMoves();
  }

  bool _hasNoLegalMoves() {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece != null && piece.color == currentTurn) {
          if (getValidMoves(r, c).isNotEmpty) return false;
        }
      }
    }
    return true;
  }

  ChessMove? makeMove(int fromRow, int fromCol, int toRow, int toCol, {PieceType? promotionType}) {
    final piece = board[fromRow][fromCol];
    if (piece == null) return null;
    if (piece.color != currentTurn) return null;

    final validMoves = getValidMoves(fromRow, fromCol);
    if (!validMoves.any((m) => m[0] == toRow && m[1] == toCol)) return null;

    ChessPiece? captured = board[toRow][toCol];
    ChessPiece? promotionPiece;
    bool isEnPassant = false;
    bool isCastling = false;
    ChessPiece? rookBefore;
    int? rookFromCol;
    int? rookToCol;

    // Handle en passant
    if (piece.type == PieceType.pawn && toCol != fromCol && captured == null) {
      captured = board[fromRow][toCol];
      board[fromRow][toCol] = null;
      isEnPassant = true;
    }

    // Handle castling
    if (piece.type == PieceType.king && (toCol - fromCol).abs() == 2) {
      isCastling = true;
      if (toCol == 6) {
        rookFromCol = 7;
        rookToCol = 5;
      } else {
        rookFromCol = 0;
        rookToCol = 3;
      }
      rookBefore = board[fromRow][rookFromCol];
      board[fromRow][rookToCol] = board[fromRow][rookFromCol]!.copyWith(hasMoved: true);
      board[fromRow][rookFromCol] = null;
    }

    // Handle promotion
    if (piece.type == PieceType.pawn && (toRow == 0 || toRow == 7)) {
      promotionType ??= PieceType.queen;
      promotionPiece = ChessPiece(type: promotionType, color: piece.color, hasMoved: true);
      board[toRow][toCol] = promotionPiece;
    } else {
      board[toRow][toCol] = piece.copyWith(hasMoved: true);
    }
    board[fromRow][fromCol] = null;

    // Update en passant target
    enPassantTargetRow = null;
    enPassantTargetCol = null;
    if (piece.type == PieceType.pawn && (toRow - fromRow).abs() == 2) {
      enPassantTargetRow = (fromRow + toRow) ~/ 2;
      enPassantTargetCol = fromCol;
    }

    // Update castling rights
    if (piece.type == PieceType.king) {
      if (piece.color == PieceColor.white) {
        whiteKingSideCastle = false;
        whiteQueenSideCastle = false;
      } else {
        blackKingSideCastle = false;
        blackQueenSideCastle = false;
      }
    }
    if (piece.type == PieceType.rook) {
      if (fromRow == 7 && fromCol == 0) whiteQueenSideCastle = false;
      if (fromRow == 7 && fromCol == 7) whiteKingSideCastle = false;
      if (fromRow == 0 && fromCol == 0) blackQueenSideCastle = false;
      if (fromRow == 0 && fromCol == 7) blackKingSideCastle = false;
    }
    if (captured?.type == PieceType.rook) {
      if (toRow == 7 && toCol == 0) whiteQueenSideCastle = false;
      if (toRow == 7 && toCol == 7) whiteKingSideCastle = false;
      if (toRow == 0 && toCol == 0) blackQueenSideCastle = false;
      if (toRow == 0 && toCol == 7) blackKingSideCastle = false;
    }

    final move = ChessMove(
      fromRow: fromRow,
      fromCol: fromCol,
      toRow: toRow,
      toCol: toCol,
      piece: piece,
      capturedPiece: captured,
      promotionPiece: promotionPiece,
      isEnPassant: isEnPassant,
      isCastling: isCastling,
      rookBefore: rookBefore,
      rookFromCol: rookFromCol,
      rookToCol: rookToCol,
    );

    moveHistory.add(move);
    currentTurn = currentTurn == PieceColor.white ? PieceColor.black : PieceColor.white;

    return move;
  }

  void _makeMoveWithoutValidation(int fromRow, int fromCol, int toRow, int toCol) {
    final piece = board[fromRow][fromCol];
    if (piece == null) return;
    board[toRow][toCol] = piece.copyWith(hasMoved: true);
    board[fromRow][fromCol] = null;
  }

  void undoMove() {
    if (moveHistory.isEmpty) return;
    final move = moveHistory.removeLast();

    board[move.fromRow][move.fromCol] = move.piece;
    board[move.toRow][move.toCol] = move.capturedPiece;

    if (move.isEnPassant) {
      board[move.fromRow][move.toCol] = move.capturedPiece;
      board[move.toRow][move.toCol] = null;
    }

    if (move.isCastling && move.rookBefore != null) {
      board[move.fromRow][move.rookFromCol!] = move.rookBefore;
      board[move.fromRow][move.rookToCol!] = null;
    }

    currentTurn = currentTurn == PieceColor.white ? PieceColor.black : PieceColor.white;
  }

  List<ChessMove> getAllLegalMoves() {
    List<ChessMove> moves = [];
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = board[r][c];
        if (piece != null && piece.color == currentTurn) {
          for (var move in getValidMoves(r, c)) {
            moves.add(ChessMove(
              fromRow: r,
              fromCol: c,
              toRow: move[0],
              toCol: move[1],
              piece: piece,
            ));
          }
        }
      }
    }
    return moves;
  }
}
