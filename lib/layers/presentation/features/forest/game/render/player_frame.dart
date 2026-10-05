import '../../../../../../core/config/constants/enum/forest/player_sheet.dart';

class PlayerFrame {
  final PlayerSheet sheet;
  final int column;
  final int row;
  final double cellSize;
  final double anchorY;

  const PlayerFrame({
    required this.sheet,
    required this.column,
    required this.row,
    required this.cellSize,
    required this.anchorY,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerFrame &&
          other.sheet == sheet &&
          other.column == column &&
          other.row == row &&
          other.cellSize == cellSize &&
          other.anchorY == anchorY;

  @override
  int get hashCode => Object.hash(sheet, column, row, cellSize, anchorY);
}
