class ArenaResultData {
  final bool isVictory;
  final String title;
  final String detail;

  const ArenaResultData({required this.isVictory, required this.title, required this.detail});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArenaResultData && other.isVictory == isVictory && other.title == title && other.detail == detail;

  @override
  int get hashCode => Object.hash(isVictory, title, detail);
}
