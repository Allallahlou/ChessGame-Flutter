import '../models/chess_piece.dart';
import '../models/chess_move.dart';
import 'chess_engine.dart';

class ChessAI {
  final PieceColor aiColor;
  final int difficulty; // 1 = Easy, 2 = Medium, 3 = Hard

  // Piece-Square Tables for positional evaluation
  static final List<List<int>> _pawnTable = [
    [0,  0,  0,  0,  0,  0,  0,  0],
    [50, 50, 50, 50, 50, 50, 50, 50],
    [10, 10, 20, 30, 30, 20, 10, 10],
    [5,  5, 10, 25, 25, 10,  5,  5],
    [0,  0,  0, 20, 20,  0,  0,  0],
    [5, -5,-10,  0,  0,-10, -5,  5],
    [5, 10, 10,-20,-20, 10, 10,  5],
    [0,  0,  0,  0,  0,  0,  0,  0],
  ];

  static final List<List<int>> _knightTable = [
    [-50,-40,-30,-30,-30,-30,-40,-50],
    [-40,-20,  0,  0,  0,  0,-20,-40],
    [-30,  0, 10, 15, 15, 10,  0,-30],
    [-30,  5, 15, 20, 20, 15,  5,-30],
    [-30,  0, 15, 20, 20, 15,  0,-30],
    [-30,  5, 10, 15, 15, 10,  5,-30],
    [-40,-20,  0,  5,  5,  0,-20,-40],
    [-50,-40,-30,-30,-30,-30,-40,-50],
  ];

  static final List<List<int>> _bishopTable = [
    [-20,-10,-10,-10,-10,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0, 10, 10, 10, 10,  0,-10],
    [-10,  5,  5, 10, 10,  5,  5,-10],
    [-10,  0,  5, 10, 10,  5,  0,-10],
    [-10, 10, 10, 10, 10, 10, 10,-10],
    [-10,  5,  0,  0,  0,  0,  5,-10],
    [-20,-10,-10,-10,-10,-10,-10,-20],
  ];

  static final List<List<int>> _rookTable = [
    [0,  0,  0,  0,  0,  0,  0,  0],
    [5, 10, 10, 10, 10, 10, 10,  5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [-5,  0,  0,  0,  0,  0,  0, -5],
    [0,  0,  0,  5,  5,  0,  0,  0],
  ];

  static final List<List<int>> _queenTable = [
    [-20,-10,-10, -5, -5,-10,-10,-20],
    [-10,  0,  0,  0,  0,  0,  0,-10],
    [-10,  0,  5,  5,  5,  5,  0,-10],
    [-5,  0,  5,  5,  5,  5,  0, -5],
    [0,  0,  5,  5,  5,  5,  0, -5],
    [-10,  5,  5,  5,  5,  5,  0,-10],
    [-10,  0,  5,  0,  0,  0,  0,-10],
    [-20,-10,-10, -5, -5,-10,-10,-20],
  ];

  static final List<List<int>> _kingMiddleGame = [
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-30,-40,-40,-50,-50,-40,-40,-30],
    [-20,-30,-30,-40,-40,-30,-30,-20],
    [-10,-20,-20,-20,-20,-20,-20,-10],
    [20, 20,  0,  0,  0,  0, 20, 20],
    [20, 30, 10,  0,  0, 10, 30, 20],
  ];

  ChessAI({required this.aiColor, this.difficulty = 2});

  ChessMove? findBestMove(ChessEngine engine) {
    final moves = engine.getAllLegalMoves();
    if (moves.isEmpty) return null;

    // Easy: 30% random moves
    if (difficulty == 1 && _randomChance(0.3)) {
      moves.shuffle();
      return moves.first;
    }

    int depth = difficulty == 1 ? 2 : (difficulty == 2 ? 3 : 4);

    ChessMove? bestMove;
    double bestValue = double.negativeInfinity;

    for (var move in moves) {
      final testEngine = engine.copy();
      testEngine.makeMove(move.fromRow, move.fromCol, move.toRow, move.toCol);

      double value = _minimax(testEngine, depth - 1, double.negativeInfinity, 
          double.infinity, false);

      if (value > bestValue) {
        bestValue = value;
        bestMove = move;
      }
    }

    return bestMove;
  }

  double _minimax(ChessEngine engine, int depth, double alpha, double beta, bool isMaximizing) {
    if (depth == 0) return _evaluateBoard(engine);
    if (engine.isCheckmate()) return isMaximizing ? -100000.0 : 100000.0;
    if (engine.isStalemate()) return 0.0;

    final moves = engine.getAllLegalMoves();

    if (isMaximizing) {
      double maxEval = double.negativeInfinity;
      for (var move in moves) {
        final testEngine = engine.copy();
        testEngine.makeMove(move.fromRow, move.fromCol, move.toRow, move.toCol);
        double eval = _minimax(testEngine, depth - 1, alpha, beta, false);
        maxEval = maxEval > eval ? maxEval : eval;
        alpha = alpha > eval ? alpha : eval;
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      double minEval = double.infinity;
      for (var move in moves) {
        final testEngine = engine.copy();
        testEngine.makeMove(move.fromRow, move.fromCol, move.toRow, move.toCol);
        double eval = _minimax(testEngine, depth - 1, alpha, beta, true);
        minEval = minEval < eval ? minEval : eval;
        beta = beta < eval ? beta : eval;
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  double _evaluateBoard(ChessEngine engine) {
    double score = 0.0;
    bool isEndgame = _isEndgame(engine);

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = engine.board[r][c];
        if (piece == null) continue;

        double pieceValue = piece.value.toDouble();
        double positionValue = _getPositionValue(piece, r, c, isEndgame);

        if (piece.color == aiColor) {
          score += pieceValue + positionValue;
        } else {
          score -= pieceValue + positionValue;
        }
      }
    }

    // Mobility bonus
    int aiMoves = _countMoves(engine, aiColor);
    int opponentMoves = _countMoves(engine, aiColor == PieceColor.white ? PieceColor.black : PieceColor.white);
    score += (aiMoves - opponentMoves) * 10;

    return score;
  }

  double _getPositionValue(ChessPiece piece, int row, int col, bool isEndgame) {
    int r = piece.color == PieceColor.white ? row : 7 - row;

    switch (piece.type) {
      case PieceType.pawn: return _pawnTable[r][col].toDouble();
      case PieceType.knight: return _knightTable[r][col].toDouble();
      case PieceType.bishop: return _bishopTable[r][col].toDouble();
      case PieceType.rook: return _rookTable[r][col].toDouble();
      case PieceType.queen: return _queenTable[r][col].toDouble();
      case PieceType.king: return isEndgame ? 0.0 : _kingMiddleGame[r][col].toDouble();
    }
  }

  bool _isEndgame(ChessEngine engine) {
    int queenCount = 0;
    int minorPieceCount = 0;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = engine.board[r][c];
        if (piece != null && piece.type == PieceType.queen) queenCount++;
        if (piece != null && (piece.type == PieceType.knight || piece.type == PieceType.bishop)) {
          minorPieceCount++;
        }
      }
    }
    return queenCount == 0 || (queenCount <= 2 && minorPieceCount <= 2);
  }

  int _countMoves(ChessEngine engine, PieceColor color) {
    int count = 0;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        final piece = engine.board[r][c];
        if (piece != null && piece.color == color) {
          count += engine.getValidMoves(r, c).length;
        }
      }
    }
    return count;
  }

  bool _randomChance(double probability) {
    return DateTime.now().millisecond / 1000 < probability;
  }
}
