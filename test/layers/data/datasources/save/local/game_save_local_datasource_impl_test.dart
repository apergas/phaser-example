import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/layers/data/datasources/save/local/game_save_local_datasource_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../../../../helpers/in_memory_preferences.dart';
import '../../../../../mocks/data/datasources/save/failing_preferences_fake.dart';
import '../../../../../mocks/data/datasources/save/save_dbo_mock.dart';
import '../../../../../mocks/data/datasources/save/save_json_mock.dart';
import '../../../../../mocks/data/repositories/save/logger_fake.dart';

void main() {
  const key = 'farming.save';
  late SharedPreferencesWithCache preferences;
  late LoggerFake logger;
  late GameSaveLocalDatasourceImpl sut;

  Future<void> createSut() async {
    preferences = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
    sut = GameSaveLocalDatasourceImpl(preferences: preferences, logger: logger);
  }

  setUp(() async {
    useInMemoryPreferences();
    logger = LoggerFake();
    await createSut();
  });

  test('testWhenThereIsNoSavedGameThenLoadReturnsNull', () {
    // given
    // when
    final dbo = sut.load();

    // then
    expect(dbo, isNull);
  });

  test('testWhenSavingThenLoadReadsTheSameDbo', () {
    // given
    final dbo = SaveDBOMock.everything;

    // when
    sut.save(dbo);
    final loaded = sut.load();

    // then
    expect(loaded, dbo);
    expect(loaded, isNot(same(dbo)));
  });

  test('testWhenSavingThenTheJsonIsStoredUnderTheSaveKey', () async {
    // given
    final dbo = SaveDBOMock.everything;

    // when
    sut.save(dbo);
    await Future<void>.delayed(Duration.zero);

    // then
    expect(preferences.getString(key), SaveJsonMock.valid);
    expect(jsonDecode(preferences.getString(key)!), dbo.toJson());
  });

  test('testWhenSavingTwiceThenLoadReadsTheLastOne', () {
    // given
    final first = SaveDBOMock.everything;
    final second = SaveDBOMock.withOtherTrees;

    // when
    sut
      ..save(first)
      ..save(second);
    final loaded = sut.load();

    // then
    expect(loaded, second);
  });

  test('testWhenClearingThenTheSavedGameIsGone', () async {
    // given
    sut.save(SaveDBOMock.everything);

    // when
    sut.clear();
    await Future<void>.delayed(Duration.zero);

    // then
    expect(sut.load(), isNull);
    expect(preferences.containsKey(key), isFalse);
  });

  test('testWhenClearingWithoutASavedGameThenNothingHappens', () async {
    // given
    // when
    sut.clear();
    await Future<void>.delayed(Duration.zero);

    // then
    expect(sut.load(), isNull);
    expect(logger.errors, isEmpty);
  });

  test('testWhenTheStoredTextIsBrokenJsonThenLoadThrows', () async {
    // given
    await preferences.setString(key, SaveJsonMock.broken);

    // when
    void load() => sut.load();

    // then
    expect(load, throwsA(isA<FormatException>()));
  });

  test('testWhenTheStoredJsonIsNotAnObjectThenLoadThrows', () async {
    // given
    await preferences.setString(key, SaveJsonMock.notAnObject);

    // when
    void load() => sut.load();

    // then
    expect(load, throwsA(isA<TypeError>()));
  });

  test('testWhenAStoredFieldHasTheWrongTypeThenLoadThrows', () async {
    // given
    await preferences.setString(key, SaveJsonMock.wrongTypes);

    // when
    void load() => sut.load();

    // then
    expect(load, throwsA(isA<TypeError>()));
  });

  test('testWhenTheStoredJsonIsEmptyThenLoadReturnsADboWithoutFields', () async {
    // given
    await preferences.setString(key, SaveJsonMock.empty);

    // when
    final dbo = sut.load();

    // then
    expect(dbo?.version, isNull);
    expect(dbo?.player, isNull);
  });

  test('testWhenTheGameIsSavedThenANewCacheOverTheSameStorageReadsIt', () async {
    // given
    sut.save(SaveDBOMock.everything);
    await Future<void>.delayed(Duration.zero);

    // when
    await createSut();
    final loaded = sut.load();

    // then
    expect(loaded, SaveDBOMock.everything);
  });

  test('testWhenWritingFailsThenTheErrorIsLoggedAndNothingIsThrown', () async {
    // given
    final failure = StateError('disk full');
    SharedPreferencesAsyncPlatform.instance = FailingPreferencesFake(error: failure);
    await createSut();

    // when
    sut.save(SaveDBOMock.everything);
    await Future<void>.delayed(Duration.zero);

    // then
    expect(logger.errors, hasLength(1));
    expect(logger.errors.single.message, '$failure');
    expect(logger.errors.single.header, 'GameSaveLocalDatasource');
    expect(logger.errors.single.stackTrace, isNotNull);
  });

  test('testWhenClearingFailsThenTheErrorIsLoggedAndNothingIsThrown', () async {
    // given
    final failure = StateError('disk locked');
    SharedPreferencesAsyncPlatform.instance = FailingPreferencesFake(error: failure);
    await createSut();

    // when
    sut.clear();
    await Future<void>.delayed(Duration.zero);

    // then
    expect(logger.errors, hasLength(1));
    expect(logger.errors.single.message, '$failure');
  });
}
