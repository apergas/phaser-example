extension KebabCase on String {
  String toKebabCase() {
    return replaceAllMapped(RegExp(r'(?<!^)[A-Z]'), (match) => '-${match[0]}').toLowerCase();
  }
}
