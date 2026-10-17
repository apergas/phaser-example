import 'package:collection/collection.dart';

import 'save_json.dart';

class SaveStatsDBO {
  final int? treesFelled;
  final Map<String, int>? treesFelledByKind;
  final int? buildingsCompleted;
  final int? treesRegrown;

  const SaveStatsDBO({this.treesFelled, this.treesFelledByKind, this.buildingsCompleted, this.treesRegrown});

  factory SaveStatsDBO.fromJson(Map<String, dynamic> json) => SaveStatsDBO(
    treesFelled: json['treesFelled'] as int?,
    treesFelledByKind: readIntMap(json['treesFelledByKind']),
    buildingsCompleted: json['buildingsCompleted'] as int?,
    treesRegrown: json['treesRegrown'] as int?,
  );

  Map<String, dynamic> toJson() => {
    'treesFelled': treesFelled,
    'treesFelledByKind': treesFelledByKind,
    'buildingsCompleted': buildingsCompleted,
    'treesRegrown': treesRegrown,
  };

  @override
  bool operator ==(Object other) =>
      other is SaveStatsDBO &&
      other.treesFelled == treesFelled &&
      const MapEquality<String, int>().equals(other.treesFelledByKind, treesFelledByKind) &&
      other.buildingsCompleted == buildingsCompleted &&
      other.treesRegrown == treesRegrown;

  @override
  int get hashCode => Object.hash(
    treesFelled,
    const MapEquality<String, int>().hash(treesFelledByKind),
    buildingsCompleted,
    treesRegrown,
  );

  @override
  String toString() =>
      'SaveStatsDBO(treesFelled: $treesFelled, treesFelledByKind: $treesFelledByKind, '
      'buildingsCompleted: $buildingsCompleted, treesRegrown: $treesRegrown)';
}
