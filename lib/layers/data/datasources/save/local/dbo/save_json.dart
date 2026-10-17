double? readDouble(Object? value) => (value as num?)?.toDouble();

Map<String, int>? readIntMap(Object? value) =>
    (value as Map<String, dynamic>?)?.map((key, amount) => MapEntry(key, amount as int));

List<String>? readStringList(Object? value) => (value as List<dynamic>?)?.map((item) => item as String).toList();

List<T>? readObjectList<T>(Object? value, T Function(Map<String, dynamic> json) fromJson) =>
    (value as List<dynamic>?)?.map((item) => fromJson(item as Map<String, dynamic>)).toList();
