import 'chess_piece.dart';

class ChessMove {
  final int fromRow;
  final int fromCol;
  final int toRow;
  final int toCol;
  final ChessPiece piece;
  final ChessPiece? capturedPiece;
  final ChessPiece? promotionPiece;
  final bool isEnPassant;
  final bool isCastling;
  final ChessPiece? rookBefore;
  final int? rookFromCol;
  final int? rookToCol;

  ChessMove({
    required this.fromRow,
    required this.fromCol,
    required this.toRow,
    required this.toCol,
    required this.piece,
    this.capturedPiece,
    this.promotionPiece,
    this.isEnPassant = false,
    this.isCastling = false,
    this.rookBefore,
    this.rookFromCol,
    this.rookToCol,
  });

  String get notation {
    const files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
    final from = '${files[fromCol]}${8 - fromRow}';
    final to = '${files[toCol]}${8 - toRow}';

    if (isCastling) {
      if (toCol == 6) return 'O-O';
      return 'O-O-O';
    }

    String pieceSymbol = '';
    if (piece.type != PieceType.pawn) {
      pieceSymbol = piece.type.name[0].toUpperCase();
      if (piece.type == PieceType.knight) pieceSymbol = 'N';
    }

    if (capturedPiece != null || isEnPassant) {
      if (piece.type == PieceType.pawn) {
        pieceSymbol = files[fromCol];
      }
      return '$pieceSymbol${from}x$to';
    }

    if (promotionPiece != null) {
      return '$from-$to=${promotionPiece!.type.name[0].toUpperCase()}';
    }

    return '$pieceSymbol$from-$to';
  }
}
