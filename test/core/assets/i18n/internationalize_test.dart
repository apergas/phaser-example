import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/core/assets/i18n/internationalize.dart';
import 'package:rpg/core/config/constants/enum/arena_level_id.dart';
import 'package:rpg/core/config/constants/enum/blueprint_id.dart';
import 'package:rpg/core/config/constants/enum/enemy_kind.dart';
import 'package:rpg/core/config/constants/enum/fight_advice.dart';
import 'package:rpg/core/config/constants/enum/forest/hero_panel_section.dart';
import 'package:rpg/core/config/constants/enum/gear_id.dart';
import 'package:rpg/core/config/constants/enum/gear_slot.dart';
import 'package:rpg/core/config/constants/enum/quest_id.dart';
import 'package:rpg/core/config/constants/enum/resource.dart';
import 'package:rpg/core/config/constants/enum/skill_id.dart';
import 'package:rpg/core/config/constants/enum/tool_kind.dart';

import '../../../helpers/spanish_translations.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  test('testWhenFormattingAmountsThenNamesTheResource', () {
    // given
    const amount = 15;

    // when
    final cost = Internationalize.forestAmount(resource: Resource.wood, amount: amount);
    final missing = Internationalize.forestMissing(
      amounts: Internationalize.forestAmount(resource: Resource.wood, amount: 5),
    );
    final gained = Internationalize.forestMessageWoodGained(wood: 6);

    // then
    expect(cost, '15 de madera');
    expect(missing, 'Faltan 5 de madera');
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
    expect(completed, 'Construcción terminada: Casa');
    expect(quest, 'Misión completada: Recoge el hacha');
  });

  test('testWhenNamingEveryResourceAndToolThenNoneFallsBackToItsKey', () {
    // given
    final texts = [
      for (final resource in Resource.values) Internationalize.forestResource(resource: resource),
      for (final resource in Resource.values) Internationalize.forestAmount(resource: resource, amount: 3),
      for (final tool in ToolKind.values) Internationalize.forestTool(tool: tool),
    ];

    // when
    final untranslated = texts.where((text) => text.contains('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
  });

  test('testWhenReadingEveryForestTextThenNoneFallsBackToItsKey', () {
    // given
    final texts = [
      Internationalize.forestResource(resource: Resource.wood),
      Internationalize.forestResource(resource: Resource.gold),
      Internationalize.forestTool(tool: ToolKind.axe),
      Internationalize.forestBuild,
      Internationalize.forestQuests,
      Internationalize.forestQuestDone,
      Internationalize.forestMessageWelcome,
      Internationalize.forestMessageNeedAxe,
      Internationalize.forestMessageBlockedPath,
      Internationalize.forestMessagePickedUpAxe,
      Internationalize.forestMessageBlockedSite,
      Internationalize.forestMessageNotEnoughResources,
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
      'Oro',
      'Hacha',
      'Construir',
      'Misiones',
      'Hecha',
      'Hay un hacha en el suelo, cerca de ti. Recógela pasando por encima.',
      'Necesitas un hacha para talar.',
      'Hay algo en medio. Acércate por otro lado.',
      '¡Hacha recogida! Haz clic en un árbol para talarlo.',
      'Ahí no cabe. Busca un sitio despejado.',
      'No tienes recursos suficientes.',
      'Manos a la obra…',
      '¡Has completado todas las misiones!',
      'Construir aquí',
      'Cancelar',
      'Mundo de juego: bosque con árboles, el personaje y los edificios',
    ]);
  });

  test('testWhenNamingEveryBlueprintThenNoneFallsBackToItsKey', () {
    // given
    final names = BlueprintId.values.map((id) => Internationalize.forestBlueprint(id: id)).toList();

    // when
    final untranslated = names.where((name) => name.contains('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
    expect(names, ['Casa', 'Herrería', 'Armería', 'Torre de magia']);
  });

  test('testWhenNamingEveryGearPieceThenUsesTheSpanishNames', () {
    // given
    final names = GearId.values.map((id) => Internationalize.forestGear(id: id)).toList();

    // when
    final untranslated = names.where((name) => name.startsWith('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
    expect(names, [
      'Hacha de leñador',
      'Espada corta',
      'Espada de hierro',
      'Espada de acero',
      'Ropa de trabajo',
      'Armadura de cuero',
      'Cota de malla',
      'Armadura de placas',
    ]);
  });

  test('testWhenReadingEveryHeroTextThenNoneFallsBackToItsKey', () {
    // given
    final texts = [
      Internationalize.forestHero,
      Internationalize.forestHeroPower,
      Internationalize.forestHeroAttack,
      Internationalize.forestHeroDefense,
      Internationalize.forestHeroHealth,
      Internationalize.forestHeroWeaponStats(attack: 7),
      Internationalize.forestHeroArmorStats(defense: 3, health: 40),
      for (final slot in GearSlot.values) Internationalize.forestHeroSlot(slot: slot),
      for (final section in HeroPanelSection.values) Internationalize.forestHeroSection(section: section),
      Internationalize.forestHeroEquipped,
      Internationalize.forestHeroBuy,
      Internationalize.forestHeroNeedsBuilding(name: 'Herrería'),
      Internationalize.forestHeroMaxed,
      Internationalize.forestMessageGearPurchased(name: 'Espada corta'),
      Internationalize.forestMessageGearNotNextTier,
    ];

    // when
    final untranslated = texts.where((text) => text.startsWith('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
    expect(texts, [
      'Héroe',
      'Poder',
      'Ataque',
      'Defensa',
      'Vida',
      'Ataque 7',
      'Defensa 3 · Vida 40',
      'Arma',
      'Armadura',
      'Equipo',
      'Habilidades',
      'En uso',
      'Comprar',
      'Construye la Herrería',
      'Ya tienes la mejor pieza',
      'Has comprado: Espada corta',
      'Antes tienes que comprar la pieza anterior.',
    ]);
  });

  test('testWhenNamingEverySkillThenUsesTheSpanishNamesAndDescriptions', () {
    // given
    // when
    final names = SkillId.values.map((id) => Internationalize.forestSkillName(id: id)).toList();
    final descriptions = SkillId.values.map((id) => Internationalize.forestSkillDescription(id: id)).toList();

    // then
    expect(names, ['Golpe doble', 'Segundo aliento', 'Esquiva']);
    expect(descriptions, [
      'Cada tercer ataque golpea dos veces.',
      'Una vez por pelea, por debajo del 30 % de vida recupera el 40 %.',
      'Un 20 % de posibilidades de esquivar cada golpe.',
    ]);
  });

  test('testWhenReadingEverySkillTextThenNoneFallsBackToItsKey', () {
    // given
    final texts = [
      Internationalize.forestHeroLearn,
      Internationalize.forestHeroKnown,
      Internationalize.forestHeroNeedsBuilding(name: Internationalize.forestBlueprint(id: BlueprintId.mageTower)),
      Internationalize.forestMessageSkillLearned(name: Internationalize.forestSkillName(id: SkillId.doubleStrike)),
      Internationalize.forestMessageSkillAlreadyKnown,
    ];

    // when
    final untranslated = texts.where((text) => text.startsWith('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
    expect(texts, [
      'Aprender',
      'Aprendida',
      'Construye la Torre de magia',
      'Has aprendido: Golpe doble',
      'Ya conoces esa habilidad.',
    ]);
  });

  test('testWhenFormattingArenaNumbersThenUsesTheSpanishTexts', () {
    // given
    const amount = 10;

    // when
    final reward = Internationalize.arenaReward(amount: amount);
    final power = Internationalize.arenaPower(power: 19);
    final heroPower = Internationalize.arenaHeroPower(power: 31);
    final damage = Internationalize.arenaDamage(amount: 4);
    final heal = Internationalize.arenaHeal(amount: 12);
    final group = Internationalize.arenaEnemyCount(count: 3, name: Internationalize.arenaEnemy(kind: EnemyKind.bandit));

    // then
    expect(reward, '+10 de oro');
    expect(power, 'Poder 19');
    expect(heroPower, 'Tu Poder: 31');
    expect(damage, '−4');
    expect(heal, '+12');
    expect(group, '3 × Bandido');
  });

  test('testWhenNamingArenaLevelsEnemiesAndAdviceThenUsesTheSpanishTexts', () {
    // given
    // when
    final levels = ArenaLevelId.values.map((id) => Internationalize.arenaLevel(id: id)).toList();
    final enemies = EnemyKind.values.map((kind) => Internationalize.arenaEnemy(kind: kind)).toList();
    final advice = FightAdvice.values.map((advice) => Internationalize.arenaAdvice(advice: advice)).toList();

    // then
    expect(levels, [
      'Bandido novato',
      'Bandido veterano',
      'Trío de bandidos',
      'Bárbaro',
      'Pareja de bárbaros',
      'Jefe bárbaro',
    ]);
    expect(enemies, ['Bandido', 'Bárbaro', 'Jefe bárbaro']);
    expect(advice, [
      '¡Casi lo tienes! Vuelve a intentarlo.',
      'Te falta Ataque: visita la Herrería.',
      'Te falta Defensa: visita la Armería.',
    ]);
    expect((Internationalize.arenaFight, Internationalize.arenaVictory), ('Empezar pelea', '¡Victoria!'));
  });
}
