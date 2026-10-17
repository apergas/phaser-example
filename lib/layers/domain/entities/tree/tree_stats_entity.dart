class TreeStatsEntity {
  final int woodYield;
  final int hitsToFell;

  const TreeStatsEntity({required this.woodYield, required this.hitsToFell})
    : assert(woodYield >= 0),
      assert(hitsToFell > 0);

  TreeStatsEntity copyWith({int? woodYield, int? hitsToFell}) {
    return TreeStatsEntity(woodYield: woodYield ?? this.woodYield, hitsToFell: hitsToFell ?? this.hitsToFell);
  }

  @override
  bool operator ==(Object other) =>
      other is TreeStatsEntity && other.woodYield == woodYield && other.hitsToFell == hitsToFell;

  @override
  int get hashCode => Object.hash(woodYield, hitsToFell);
}
