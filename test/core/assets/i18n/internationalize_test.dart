import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';

import '../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  test('testWhenFormattingCostsThenInsertsTheWood', () {
    // given
    const wood = 15;

    // when
    final cost = Internationalize.forestCost(wood: wood);
    final missing = Internationalize.forestMissing(wood: 5);
    final gained = Internationalize.forestMessageWoodGained(wood: 6);

    // then
    expect(cost, '15 de madera');
    expect(missing, 'Faltan 5');
    expect(gained, '+6 de madera');
  });

  test('testWhenNamingBlueprintsAndQuestsThenUsesTheSpanishTitles', () {
    // given
    const blueprint = BlueprintId.house;

    // when
    final name = Internationalize.forestBlueprint(id: blueprint);
    final quests = QuestId.values.map((id) => Internationalize.forestQuestTitle(id: id)).toList();

    // then
    expect(name, 'Casa');
    expect(quests, ['Recoge el hacha', 'Consigue al menos 15 de madera', 'Construye una casa']);
  });

  test('testWhenFormattingMessagesWithNamesThenInsertsThem', () {
    // given
    const name = 'Casa';

    // when
    final placing = Internationalize.forestMessagePlacing(name: name);
    final completed = Internationalize.forestMessageBuildingCompleted(name: name);
    final quest = Internationalize.forestMessageQuestCompleted(title: 'Recoge el hacha');

    // then
    expect(placing, 'Elige dónde construir: Casa. Clic derecho o Esc para cancelar.');
    expect(completed, '¡Casa construida!');
    expect(quest, 'Misión completada: Recoge el hacha');
  });

  test('testWhenReadingEveryForestTextThenNoneFallsBackToItsKey', () {
    // given
    final texts = [
      Internationalize.forestWood,
      Internationalize.forestAxe,
      Internationalize.forestBuild,
      Internationalize.forestQuests,
      Internationalize.forestQuestDone,
      Internationalize.forestMessageWelcome,
      Internationalize.forestMessageNeedAxe,
      Internationalize.forestMessageBlockedPath,
      Internationalize.forestMessagePickedUpAxe,
      Internationalize.forestMessageBlockedSite,
      Internationalize.forestMessageNotEnoughWood,
      Internationalize.forestMessageBuildingStarted,
      Internationalize.forestMessageAllQuestsCompleted,
      Internationalize.forestPlacementConfirm,
      Internationalize.forestPlacementCancel,
      Internationalize.forestAccessibilityGameWorld,
    ];

    // when
    final untranslated = texts.where((text) => text.startsWith('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
    expect(texts, [
      'Madera',
      'Hacha',
      'Construir',
      'Misiones',
      'Hecha',
      'Hay un hacha en el suelo, cerca de ti. Recógela pasando por encima.',
      'Necesitas un hacha para talar.',
      'Hay algo en medio. Acércate por otro lado.',
      '¡Hacha recogida! Haz clic en un árbol para talarlo.',
      'Ahí no cabe. Busca un sitio despejado.',
      'No tienes madera suficiente.',
      'Manos a la obra…',
      '¡Has completado todas las misiones!',
      'Construir aquí',
      'Cancelar',
      'Mundo de juego: bosque con árboles, el personaje y los edificios',
    ]);
  });
}
