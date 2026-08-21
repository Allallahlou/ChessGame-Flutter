import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chess_piece.dart';
import '../models/chess_move.dart';
import '../logic/chess_engine.dart';
import '../logic/chess_ai.dart';
import '../widgets/chess_board_widget.dart';
import '../utils/constants.dart';

enum PlayerColor { white, black }

class GameScreen extends StatefulWidget {
  final PlayerColor playerColor;
  final int difficulty;
  final bool vsComputer;
  final String username;

  const GameScreen({
    super.key,
    required this.playerColor,
    this.difficulty = 2,
    this.vsComputer = true,
    required this.username,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late ChessEngine engine;
  late ChessAI? ai;

  int? selectedRow;
  int? selectedCol;
  List<List<int>> validMoves = [];
  ChessMove? lastMove;
  List<int>? kingInCheck;

  bool gameOver = false;
  String gameMessage = '';
  bool isCheck = false;

  Timer? gameTimer;
  int whiteTime = 600;
  int blackTime = 600;

  List<ChessPiece> capturedByWhite = [];
  List<ChessPiece> capturedByBlack = [];

  bool isFlipped = false;
  bool showPromotionDialog = false;
  int? promotionRow;
  int? promotionCol;
  int? promotionFromRow;
  int? promotionFromCol;

  late AnimationController _pieceAnimationController;

  @override
  void initState() {
    super.initState();
    engine = ChessEngine();
    isFlipped = widget.playerColor == PlayerColor.black;

    if (widget.vsComputer) {
      final aiColor = widget.playerColor == PlayerColor.white 
        ? PieceColor.black 
        : PieceColor.white;
      ai = ChessAI(aiColor: aiColor, difficulty: widget.difficulty);

      // If AI is white, make first move
      if (aiColor == PieceColor.white) {
        Future.delayed(const Duration(milliseconds: 800), _makeAIMove);
      }
    } else {
      ai = null;
    }

    _pieceAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    startTimer();
  }

  void startTimer() {
    gameTimer?.cancel();
    gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (gameOver) {
        gameTimer?.cancel();
        return;
      }
      setState(() {
        if (engine.currentTurn == PieceColor.white) {
          if (whiteTime > 0) whiteTime--;
        } else {
          if (blackTime > 0) blackTime--;
        }
      });

      if (whiteTime == 0 || blackTime == 0) {
        gameTimer?.cancel();
        setState(() {
          gameOver = true;
          gameMessage = whiteTime == 0 ? 'Black wins on time!' : 'White wins on time!';
        });
        _saveGameResult(whiteTime == 0 ? PieceColor.black : PieceColor.white);
      }
    });
  }

  void _makeAIMove() {
    if (gameOver || ai == null) return;
    if (engine.currentTurn != ai!.aiColor) return;

    final move = ai!.findBestMove(engine);
    if (move != null) {
      _executeMove(move.fromRow, move.fromCol, move.toRow, move.toCol);
    }
  }

  void _onSquareTap(int row, int col) {
    if (gameOver) return;
    if (widget.vsComputer && engine.currentTurn == ai?.aiColor) return;

    // If promotion dialog is showing, ignore taps
    if (showPromotionDialog) return;

    // If a piece is already selected
    if (selectedRow != null && selectedCol != null) {
      // Check if tapped square is a valid move
      if (validMoves.any((m) => m[0] == row && m[1] == col)) {
        _executeMove(selectedRow!, selectedCol!, row, col);
        setState(() {
          selectedRow = null;
          selectedCol = null;
          validMoves = [];
        });
        return;
      }

      // If tapped another own piece, select it instead
      final piece = engine.board[row][col];
      if (piece != null && piece.color == engine.currentTurn) {
        setState(() {
          selectedRow = row;
          selectedCol = col;
          validMoves = engine.getValidMoves(row, col);
        });
        return;
      }

      // Deselect
      setState(() {
        selectedRow = null;
        selectedCol = null;
        validMoves = [];
      });
      return;
    }

    // Select a piece
    final piece = engine.board[row][col];
    if (piece != null && piece.color == engine.currentTurn) {
      setState(() {
        selectedRow = row;
        selectedCol = col;
        validMoves = engine.getValidMoves(row, col);
      });
    }
  }

  void _onPieceDragStarted(int row, int col) {
    if (gameOver) return;
    if (widget.vsComputer && engine.currentTurn == ai?.aiColor) return;

    final piece = engine.board[row][col];
    if (piece != null && piece.color == engine.currentTurn) {
      setState(() {
        selectedRow = row;
        selectedCol = col;
        validMoves = engine.getValidMoves(row, col);
      });
    }
  }

  void _onPieceDropped(int row, int col) {
    if (selectedRow != null && selectedCol != null) {
      if (validMoves.any((m) => m[0] == row && m[1] == col)) {
        _executeMove(selectedRow!, selectedCol!, row, col);
      }
      setState(() {
        selectedRow = null;
        selectedCol = null;
        validMoves = [];
      });
    }
  }

  void _executeMove(int fromRow, int fromCol, int toRow, int toCol) {
    final piece = engine.board[fromRow][fromCol];

    // Check for promotion
    if (piece?.type == PieceType.pawn && (toRow == 0 || toRow == 7)) {
      setState(() {
        showPromotionDialog = true;
        promotionRow = toRow;
        promotionCol = toCol;
        promotionFromRow = fromRow;
        promotionFromCol = fromCol;
      });
      return;
    }

    _completeMove(fromRow, fromCol, toRow, toCol);
  }

  void _completeMove(int fromRow, int fromCol, int toRow, int toCol, {PieceType? promotion}) {
    final captured = engine.board[toRow][toCol];
    final move = engine.makeMove(fromRow, fromCol, toRow, toCol, promotionType: promotion);

    if (move == null) return;

    // Track captured pieces
    if (captured != null) {
      if (captured.color == PieceColor.white) {
        capturedByBlack.add(captured);
      } else {
        capturedByWhite.add(captured);
      }
    }
    if (move.isEnPassant && move.capturedPiece != null) {
      if (move.capturedPiece!.color == PieceColor.white) {
        capturedByBlack.add(move.capturedPiece!);
      } else {
        capturedByWhite.add(move.capturedPiece!);
      }
    }

    setState(() {
      lastMove = move;
      showPromotionDialog = false;
      promotionRow = null;
      promotionCol = null;
      promotionFromRow = null;
      promotionFromCol = null;

      isCheck = engine.isKingInCheck(engine.currentTurn);

      if (engine.isCheckmate()) {
        gameOver = true;
        gameMessage = '${engine.currentTurn == PieceColor.white ? "Black" : "White"} wins by checkmate!';
        gameTimer?.cancel();
        _saveGameResult(engine.currentTurn == PieceColor.white ? PieceColor.black : PieceColor.white);
      } else if (engine.isStalemate()) {
        gameOver = true;
        gameMessage = 'Stalemate! It\'s a draw!';
        gameTimer?.cancel();
      }

      // Find king in check
      kingInCheck = null;
      if (isCheck && !gameOver) {
        for (int r = 0; r < 8; r++) {
          for (int c = 0; c < 8; c++) {
            final p = engine.board[r][c];
            if (p != null && p.type == PieceType.king && p.color == engine.currentTurn) {
              kingInCheck = [r, c];
              break;
            }
          }
        }
      }
    });

    // Trigger AI move
    if (!gameOver && widget.vsComputer && engine.currentTurn == ai?.aiColor) {
      Future.delayed(const Duration(milliseconds: 600), _makeAIMove);
    }
  }

  void _onPromotionSelected(PieceType type) {
    if (promotionFromRow != null && promotionFromCol != null && 
        promotionRow != null && promotionCol != null) {
      _completeMove(promotionFromRow!, promotionFromCol!, promotionRow!, promotionCol!, 
        promotion: type);
    }
  }

  void _undoMove() {
    if (engine.moveHistory.isEmpty || gameOver) return;

    // Undo twice if vs computer (player + AI)
    engine.undoMove();
    if (widget.vsComputer && engine.moveHistory.isNotEmpty) {
      engine.undoMove();
    }

    setState(() {
      lastMove = engine.moveHistory.isNotEmpty ? engine.moveHistory.last : null;
      isCheck = engine.isKingInCheck(engine.currentTurn);
      gameOver = false;
      gameMessage = '';
      kingInCheck = null;
    });
  }

  void _restartGame() {
    setState(() {
      engine.resetBoard();
      selectedRow = null;
      selectedCol = null;
      validMoves = [];
      lastMove = null;
      kingInCheck = null;
      gameOver = false;
      gameMessage = '';
      isCheck = false;
      whiteTime = 600;
      blackTime = 600;
      capturedByWhite = [];
      capturedByBlack = [];
    });
    startTimer();

    if (widget.vsComputer && ai?.aiColor == PieceColor.white) {
      Future.delayed(const Duration(milliseconds: 800), _makeAIMove);
    }
  }

  Future<void> _saveGameResult(PieceColor winner) async {
    final prefs = await SharedPreferences.getInstance();
    final played = (prefs.getInt('games_played') ?? 0) + 1;
    await prefs.setInt('games_played', played);

    final playerColor = widget.playerColor == PlayerColor.white ? PieceColor.white : PieceColor.black;
    if (winner == playerColor) {
      final won = (prefs.getInt('games_won') ?? 0) + 1;
      await prefs.setInt('games_won', won);
    }
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    _pieceAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),

            // Captured pieces & Timer for top player
            _buildPlayerInfo(
              color: isFlipped ? PieceColor.white : PieceColor.black,
              time: isFlipped ? whiteTime : blackTime,
              captured: isFlipped ? capturedByWhite : capturedByBlack,
              isActive: engine.currentTurn == (isFlipped ? PieceColor.white : PieceColor.black),
            ),

            // Chess Board
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ChessBoardWidget(
                    board: engine.board,
                    selectedRow: selectedRow,
                    selectedCol: selectedCol,
                    validMoves: validMoves,
                    lastMove: lastMove,
                    kingInCheck: kingInCheck,
                    isFlipped: isFlipped,
                    onSquareTap: _onSquareTap,
                    onPieceDragStarted: _onPieceDragStarted,
                    onPieceDropped: _onPieceDropped,
                  ),
                ),
              ),
            ),

            // Captured pieces & Timer for bottom player
            _buildPlayerInfo(
              color: isFlipped ? PieceColor.black : PieceColor.white,
              time: isFlipped ? blackTime : whiteTime,
              captured: isFlipped ? capturedByBlack : capturedByWhite,
              isActive: engine.currentTurn == (isFlipped ? PieceColor.black : PieceColor.white),
            ),

            // Bottom controls
            _buildBottomControls(),

            // Promotion Dialog
            if (showPromotionDialog) _buildPromotionDialog(),

            // Game Over Dialog
            if (gameOver) _buildGameOverDialog(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
          ),
          const Spacer(),
          if (isCheck && !gameOver)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.checkHighlight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.checkHighlight),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber, color: AppColors.checkHighlight, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'CHECK!',
                    style: TextStyle(
                      color: AppColors.checkHighlight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          IconButton(
            onPressed: () => setState(() => isFlipped = !isFlipped),
            icon: const Icon(Icons.flip, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerInfo({
    required PieceColor color,
    required int time,
    required List<ChessPiece> captured,
    required bool isActive,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive 
          ? Colors.white.withOpacity(0.1) 
          : Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive 
            ? AppColors.accent.withOpacity(0.5) 
            : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Text(
            color == PieceColor.white ? '♔ White' : '♚ Black',
            style: TextStyle(
              color: color == PieceColor.white ? Colors.white : Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          if (captured.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: captured.map((p) => Text(p.symbol, style: const TextStyle(fontSize: 16))).toList(),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent.withOpacity(0.3) : Colors.black26,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatTime(time),
              style: TextStyle(
                color: time < 60 ? Colors.red : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.undo,
            label: 'Undo',
            onTap: _undoMove,
          ),
          _buildControlButton(
            icon: Icons.restart_alt,
            label: 'Restart',
            onTap: _restartGame,
          ),
          _buildControlButton(
            icon: Icons.home,
            label: 'Home',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPromotionDialog() {
    final pieceColor = engine.currentTurn == PieceColor.white ? PieceColor.black : PieceColor.white;
    final pieces = [
      PieceType.queen,
      PieceType.rook,
      PieceType.bishop,
      PieceType.knight,
    ];

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.darkerBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Promote Pawn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: pieces.map((type) {
                  final piece = ChessPiece(type: type, color: pieceColor);
                  return GestureDetector(
                    onTap: () => _onPromotionSelected(type),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Center(
                        child: Text(
                          piece.symbol,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOverDialog() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.darkerBackground,
                AppColors.darkBackground,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.accent.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '♚',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 16),
              Text(
                gameMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _restartGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Play Again', style: TextStyle(fontSize: 16)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Home', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
