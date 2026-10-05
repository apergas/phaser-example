class AtlasFrame {
  final String name;
  final int x;
  final int y;
  final int width;
  final int height;
  final double pivotX;
  final double pivotY;

  const AtlasFrame({
    required this.name,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.pivotX,
    required this.pivotY,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AtlasFrame &&
          other.name == name &&
          other.x == x &&
          other.y == y &&
          other.width == width &&
          other.height == height &&
          other.pivotX == pivotX &&
          other.pivotY == pivotY;

  @override
  int get hashCode => Object.hash(name, x, y, width, height, pivotX, pivotY);
}
