class SeededRandom {
  static const int _multiplier = 1664525;
  static const int _increment = 1013904223;
  static const int _mask = 0xFFFFFFFF;
  static const double _modulus = 4294967296;

  int _state;

  SeededRandom(int seed) : _state = seed & _mask;

  double next() {
    _state = (_state * _multiplier + _increment) & _mask;
    return _state / _modulus;
  }
}
