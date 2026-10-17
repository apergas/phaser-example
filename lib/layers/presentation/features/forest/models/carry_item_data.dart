class CarryItemData {
  final String text;
  final bool isFull;

  const CarryItemData({required this.text, required this.isFull});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CarryItemData && other.text == text && other.isFull == isFull;

  @override
  int get hashCode => Object.hash(text, isFull);
}
