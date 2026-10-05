import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/utils/seeded_random.dart';

void main() {
  test('testWhenSeededWith42ThenProducesTheGoldenSequence', () {
    // given
    final random = SeededRandom(42);

    // when
    final values = [for (var i = 0; i < 5; i++) random.next()];

    // then
    expect(values, [
      0.2523451747838408,
      0.08812504541128874,
      0.5772811982315034,
      0.22255426598712802,
      0.37566019711084664,
    ]);
  });
}
