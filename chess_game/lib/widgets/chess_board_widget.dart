import 'package:flutter/material.dart';
import '../models/chess_piece.dart';
import '../models/chess_move.dart';
import '../utils/constants.dart';

class ChessBoardWidget extends StatelessWidget {
  final List<List<ChessPiece?>> board;
  final int? selectedRow;
  final int? selectedCol;
  final List<List<int>> validMoves;
  final ChessMove? lastMove;
  final List<int>? kingInCheck;
  final bool isFlipped;
  final Function(int row, int col) onSquareTap;
  final Function(int row, int col) onPieceDragStarted;
  final Function(int row, int col) onPieceDropped;

  const ChessBoardWidget({
    super.key,
    required this.board,
    this.selectedRow,
    this.selectedCol,
    required this.validMoves,
    this.lastMove,
    this.kingInCheck,
    this.isFlipped = false,
    required this.onSquareTap,
    required this.onPieceDragStarted,
    required this.onPieceDropped,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: List.generate(8, (row) {
              final displayRow = isFlipped ? 7 - row : row;
              return Expanded(
                child: Row(
                  children: List.generate(8, (col) {
                    final displayCol = isFlipped ? 7 - col : col;
                    return _buildSquare(displayRow, displayCol);
                  }),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSquare(int row, int col) {
    final piece = board[row][col];
    final isLight = (row + col) % 2 == 0;
    final isSelected = selectedRow == row && selectedCol == col;
    final isValidMove = validMoves.any((m) => m[0] == row && m[1] == col);
    final isLastMove = lastMove != null && 
        ((lastMove!.fromRow == row && lastMove!.fromCol == col) ||
         (lastMove!.toRow == row && lastMove!.toCol == col));
    final isCheck = kingInCheck != null && kingInCheck![0] == row && kingInCheck![1] == col;

    Color squareColor;
    if (isCheck) {
      squareColor = AppColors.checkHighlight.withOpacity(0.7);
    } else if (isSelected) {
      squareColor = AppColors.highlight.withOpacity(0.6);
    } else if (isLastMove) {
      squareColor = AppColors.lastMove.withOpacity(0.4);
    } else {
      squareColor = isLight ? AppColors.lightSquare : AppColors.darkSquare;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () => onSquareTap(row, col),
        child: DragTarget<int>(
          onAcceptWithDetails: (details) => onPieceDropped(row, col),
          builder: (context, candidateData, rejectedData) {
            return Container(
              color: squareColor,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isValidMove && piece == null)
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppColors.possibleMove.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  if (isValidMove && piece != null)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.possibleMove.withOpacity(0.8),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  if (piece != null)
                    Draggable<int>(
                      data: row * 8 + col,
                      feedback: _buildPiece(piece, 50),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _buildPiece(piece, 40),
                      ),
                      onDragStarted: () => onPieceDragStarted(row, col),
                      child: _buildPiece(piece, 40),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPiece(ChessPiece piece, double size) {
    return Text(
      piece.symbol,
      style: TextStyle(
        fontSize: size,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }
}
