enum PieceType {
  king,
  queen,
  rook,
  bishop,
  knight,
  pawn,
}

enum PieceColor {
  white,
  black,
}

class ChessPiece {
  final PieceType type;
  final PieceColor color;
  bool hasMoved;

  ChessPiece({
    required this.type,
    required this.color,
    this.hasMoved = false,
  });

  ChessPiece copyWith({
    PieceType? type,
    PieceColor? color,
    bool? hasMoved,
  }) {
    return ChessPiece(
      type: type ?? this.type,
      color: color ?? this.color,
      hasMoved: hasMoved ?? this.hasMoved,
    );
  }

  String get symbol {
    switch (color) {
      case PieceColor.white:
        switch (type) {
          case PieceType.king: return '♔';
          case PieceType.queen: return '♕';
          case PieceType.rook: return '♖';
          case PieceType.bishop: return '♗';
          case PieceType.knight: return '♘';
          case PieceType.pawn: return '♙';
        }
      case PieceColor.black:
        switch (type) {
          case PieceType.king: return '♚';
          case PieceType.queen: return '♛';
          case PieceType.rook: return '♜';
          case PieceType.bishop: return '♝';
          case PieceType.knight: return '♞';
          case PieceType.pawn: return '♟';
        }
    }
  }

  int get value {
    switch (type) {
      case PieceType.king: return 20000;
      case PieceType.queen: return 900;
      case PieceType.rook: return 500;
      case PieceType.bishop: return 330;
      case PieceType.knight: return 320;
      case PieceType.pawn: return 100;
    }
  }
}
