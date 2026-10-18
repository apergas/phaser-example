@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/error-handling/exceptions/app_exceptions.dart';
import 'package:farming/core/error-handling/handlers/app_exception_handler.dart';
import 'package:farming/layers/data/datasources/save/local/game_save_local_datasource_impl.dart';
import 'package:farming/layers/data/repositories/save/game_save_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/in_memory_preferences.dart';
import '../../../../helpers/spanish_translations.dart';
import '../../../../mocks/core/error-handling/app_exception_mock.dart';
import '../../../../mocks/data/datasources/save/game_save_local_datasource_fake.dart';
import '../../../../mocks/data/datasources/save/save_dbo_mock.dart';
import '../../../../mocks/data/datasources/save/save_json_mock.dart';
import '../../../../mocks/data/repositories/save/logger_fake.dart';
import '../../../../mocks/data/repositories/save/same_game_matcher.dart';
import '../../../../mocks/data/repositories/save/save_error_mock.dart';
import '../../../../mocks/data/repositories/save/save_mapper_dbo_factory.dart';
import '../../../../mocks/data/repositories/save/save_round_trip_mock.dart';
import '../../../../mocks/domain/game/save_scenario_mock.dart';

void main() {
  late GameSaveLocalDatasourceFake localDatasource;
  late LoggerFake logger;
  late GameSaveRepositoryImpl sut;

  setUpAll(loadSpanishTranslations);

  setUp(() {
    localDatasource = GameSaveLocalDatasourceFake();
    logger = LoggerFake();
    sut = GameSaveRepositoryImpl(
      localDatasource: localDatasource,
      saveMapperDBO: makeSaveMapperDBO(),
      appExceptionHandler: AppExceptionHandler(),
      logger: logger,
    );
  });

  test('testWhenThereIsNoSavedGameThenLoadReturnsNullWithoutLogging', () {
    // given
    localDatasource.stored = null;

    // when
    final session = sut.load();

    // then
    expect(session, isNull);
    expect(localDatasource.loadCalls, 1);
    expect(logger.errors, isEmpty);
  });

  test('testWhenTheSavedGameIsValidThenLoadReturnsTheSession', () {
    // given
    localDatasource.stored = SaveDBOMock.everything;

    // when
    final session = sut.load();

    // then
    expectSameGame(session!, SaveRoundTripMock.session());
    expect(logger.errors, isEmpty);
  });

  test('testWhenTheVersionIsUnknownThenLoadReturnsNullAndLogsTheReason', () {
    // given
    localDatasource.stored = SaveDBOMock.otherVersion;

    // when
    final session = sut.load();

    // then
    expect(session, isNull);
    expect(logger.errors, hasLength(1));
    expect(
      logger.errors.single.message,
      contains(Internationalize.errorInvalidSaveMessage(reason: 'unknown version 3')),
    );
    expect(logger.errors.single.header, 'GameSaveRepository');
    expect(logger.errors.single.stackTrace, isNotNull);
  });

  test('testWhenTheDataIsOutOfRangeThenLoadReturnsNullAndLogsTheReason', () {
    // given
    localDatasource.stored = SaveDBOMock.withBadTree;

    // when
    final session = sut.load();

    // then
    expect(session, isNull);
    expect(logger.errors, hasLength(1));
    expect(
      logger.errors.single.message,
      contains(Internationalize.errorInvalidSaveMessage(reason: 'tree tree-1: 7 hits taken of 7')),
    );
  });

  test('testWhenTheDatasourceThrowsThenLoadReturnsNullAndLogsAGenericError', () {
    // given
    localDatasource.loadError = SaveErrorMock.brokenJson;

    // when
    final session = sut.load();

    // then
    expect(session, isNull);
    expect(logger.errors, hasLength(1));
    expect(logger.errors.single.message, startsWith(Internationalize.errorGenericMessage));
    expect(logger.errors.single.message, endsWith('(${SaveErrorMock.brokenJson})'));
  });

  test('testWhenSavingThenTheDatasourceReceivesTheDboOfTheSession', () {
    // given
    final session = SaveRoundTripMock.session();

    // when
    sut.save(session);

    // then
    expect(localDatasource.saved, hasLength(1));
    expect(localDatasource.saved.single.version, 2);
    expect(localDatasource.saved.single.completedQuests, ['gatherWood', 'buildHouse', 'buildForge']);
    expect(sut.load(), isNotNull);
    expect(logger.errors, isEmpty);
  });

  test('testWhenSavingFailsWithAnAppExceptionThenItIsThrownAsIsAndLogged', () {
    // given
    localDatasource.saveError = AppExceptionMock.invalidSave;

    // when
    void save() => sut.save(SaveRoundTripMock.session());

    // then
    expect(save, throwsA(same(AppExceptionMock.invalidSave)));
    expect(logger.errors, hasLength(1));
    expect(logger.errors.single.header, 'GameSaveRepository');
  });

  test('testWhenSavingFailsWithAnotherErrorThenItBecomesAGenericException', () {
    // given
    localDatasource.saveError = SaveErrorMock.storageFailure;

    // when
    void save() => sut.save(SaveRoundTripMock.session());

    // then
    expect(save, throwsA(isA<GenericException>()));
    expect(logger.errors, hasLength(1));
    expect(logger.errors.single.message, contains('${SaveErrorMock.storageFailure}'));
  });

  test('testWhenClearingThenTheDatasourceClearsTheSave', () {
    // given
    localDatasource.stored = SaveDBOMock.everything;

    // when
    sut.clear();

    // then
    expect(localDatasource.clearCalls, 1);
    expect(sut.load(), isNull);
  });

  test('testWhenClearingFailsThenItThrowsTheHandledExceptionAndLogs', () {
    // given
    localDatasource.clearError = SaveErrorMock.storageFailure;

    // when
    void clear() => sut.clear();

    // then
    expect(clear, throwsA(isA<GenericException>()));
    expect(logger.errors, hasLength(1));
  });

  test('testWhenClearingFailsWithAnAppExceptionThenItIsThrownAsIs', () {
    // given
    localDatasource.clearError = AppExceptionMock.invalidSave;

    // when
    void clear() => sut.clear();

    // then
    expect(clear, throwsA(same(AppExceptionMock.invalidSave)));
  });

  group('overTheRealDatasource', () {
    const key = 'farming.save';
    late SharedPreferencesWithCache preferences;

    setUp(() async {
      useInMemoryPreferences();
      preferences = await SharedPreferencesWithCache.create(cacheOptions: const SharedPreferencesWithCacheOptions());
      sut = GameSaveRepositoryImpl(
        localDatasource: GameSaveLocalDatasourceImpl(preferences: preferences, logger: logger),
        saveMapperDBO: makeSaveMapperDBO(),
        appExceptionHandler: AppExceptionHandler(),
        logger: logger,
      );
    });

    test('testWhenSavingAndLoadingThenTheGameComesBackFromTheJson', () {
      // given
      final session = SaveRoundTripMock.session();

      // when
      sut.save(session);
      final loaded = sut.load();

      // then
      expectSameGame(loaded!, session);
      expect(logger.errors, isEmpty);
    });

    test('testWhenAVersionOneGameIsStoredThenItLoadsMigrated', () async {
      // given
      await preferences.setString(key, SaveJsonMock.versionOne);

      // when
      final loaded = sut.load();

      // then
      expect(loaded!.world.stock, SaveScenarioMock.stockWithTheVersionOneLoad);
      expect(loaded.world.buildings, SaveScenarioMock.everything().buildings);
      expect(loaded.quests.completed, SaveScenarioMock.completedQuests);
      expect(logger.errors, isEmpty);
    });

    test('testWhenTheStoredTextIsNotAValidSaveThenLoadReturnsNullAndLogsOnce', () async {
      // given
      final texts = [
        SaveJsonMock.broken,
        SaveJsonMock.notJson,
        SaveJsonMock.notAnObject,
        SaveJsonMock.wrongTypes,
        SaveJsonMock.empty,
        SaveJsonMock.otherVersion,
        SaveJsonMock.outOfRange,
        SaveJsonMock.withoutPlayer,
      ];

      // when
      final loaded = <Object?>[];
      for (final text in texts) {
        await preferences.setString(key, text);
        loaded.add(sut.load());
      }

      // then
      expect(loaded, everyElement(isNull));
      expect(logger.errors, hasLength(texts.length));
    });

    test('testWhenClearingThenTheStoredGameIsRemoved', () async {
      // given
      sut.save(SaveRoundTripMock.session());

      // when
      sut.clear();
      await Future<void>.delayed(Duration.zero);

      // then
      expect(sut.load(), isNull);
      expect(preferences.containsKey(key), isFalse);
    });
  });
}
