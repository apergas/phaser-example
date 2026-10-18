import 'package:flutter_test/flutter_test.dart';
import 'package:farming/core/assets/i18n/internationalize.dart';
import 'package:farming/core/config/constants/enum/arena_level_id.dart';
import 'package:farming/core/config/constants/enum/blueprint_id.dart';
import 'package:farming/core/config/constants/enum/construction_rejection.dart';
import 'package:farming/core/config/constants/enum/enemy_kind.dart';
import 'package:farming/core/config/constants/enum/fight_advice.dart';
import 'package:farming/core/config/constants/enum/forest/hero_panel_section.dart';
import 'package:farming/core/config/constants/enum/gear_id.dart';
import 'package:farming/core/config/constants/enum/gear_slot.dart';
import 'package:farming/core/config/constants/enum/quest_id.dart';
import 'package:farming/core/config/constants/enum/quest_line.dart';
import 'package:farming/core/config/constants/enum/resource.dart';
import 'package:farming/core/config/constants/enum/skill_id.dart';
import 'package:farming/core/config/constants/enum/tool_kind.dart';
import 'package:farming/core/config/constants/enum/upgrade_id.dart';

import '../../../helpers/spanish_translations.dart';
import '../../../mocks/domain/world/funds_mock.dart';

void main() {
  setUpAll(loadSpanishTranslations);

  test('testWhenFormattingAmountsThenNamesTheResource', () {
    // given
    const amount = 15;

    // when
    final cost = Internationalize.forestAmount(resource: Resource.wood, amount: amount);
    final mana = Internationalize.forestAmount(resource: Resource.mana, amount: 20);
    final missing = Internationalize.forestMissing(
      amounts: Internationalize.forestAmount(resource: Resource.wood, amount: 5),
    );
    final gained = Internationalize.forestMessageWoodGained(wood: 6);

    // then
    expect(cost, '15 de madera');
    expect(mana, '20 de maná');
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
    expect(quests, [
      'Reúne 15 de madera',
      'Construye una casa',
      'Construye la Herrería',
      'Gana un nivel de la arena',
      'Compra la Espada corta',
      'Construye la Armería',
      'Construye la Torre de magia',
      'Aprende una habilidad',
      'Gana la mitad de los niveles de la arena',
      'Gana al Jefe bárbaro',
      'Tala 10 árboles',
      'Tala un roble',
      'Ten 40 de madera en el almacén',
      'Ten 2 casas terminadas',
      'Ve rebrotar un árbol',
      'Ten 20 de piedra en el almacén',
      'Construye el Taller',
      'Compra el Hacha de hierro',
    ]);
    expect(QuestLine.values.map((line) => Internationalize.forestQuestLine(line: line)), ['Aldea', 'Héroe']);
  });

  test('testWhenFormattingMessagesWithNamesThenInsertsThem', () {
    // given
    const name = 'Casa';

    // when
    final placing = Internationalize.forestMessagePlacing(name: name);
    final placingTouch = Internationalize.forestMessagePlacingTouch(name: name);
    final completed = Internationalize.forestMessageBuildingCompleted(name: name);
    final quest = Internationalize.forestMessageQuestCompleted(title: 'Tala un roble');

    // then
    expect(placing, 'Elige dónde construir: Casa. Clic derecho o Esc para cancelar.');
    expect(
      placingTouch,
      'Elige dónde construir: Casa. Arrastra el dedo para moverlo y toca Construir aquí o Cancelar.',
    );
    expect(completed, 'Construcción terminada: Casa');
    expect(quest, 'Misión completada: Tala un roble');
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
      Internationalize.forestResource(resource: Resource.mana),
      Internationalize.forestResource(resource: Resource.stone),
      Internationalize.forestTool(tool: ToolKind.axe),
      Internationalize.forestTool(tool: ToolKind.pickaxe),
      Internationalize.forestBuild,
      Internationalize.forestQuests,
      Internationalize.forestQuestDone,
      Internationalize.forestMessageWelcome,
      Internationalize.forestMessageNeedAxe,
      Internationalize.forestMessageNeedPickaxe,
      Internationalize.forestMessageBlockedPath,
      Internationalize.forestMessagePickedUpPickaxe,
      Internationalize.forestMessagePickedUpPickaxeTouch,
      Internationalize.forestMessageBlockedSite,
      Internationalize.forestMessageNotEnoughResources,
      Internationalize.forestMessageBuildingStarted,
      Internationalize.forestMessageQuestLineCompleted(line: QuestLine.village),
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
      'Maná',
      'Piedra',
      'Hacha',
      'Pico',
      'Construir',
      'Misiones',
      'Hecha',
      'Tala árboles para reunir madera y construir tu aldea.',
      'Necesitas un hacha para talar.',
      'Necesitas un pico para picar.',
      'Hay algo en medio. Acércate por otro lado.',
      '¡Pico recogido! Haz clic en una roca para picarla.',
      '¡Pico recogido! Toca una roca para picarla.',
      'Ahí no cabe. Busca un sitio despejado.',
      'No tienes recursos suficientes.',
      'Manos a la obra…',
      '¡Has completado las misiones de Aldea!',
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
    expect(names, ['Casa', 'Herrería', 'Armería', 'Torre de magia', 'Taller']);
  });

  test('testWhenFormattingTheVillageTextsThenUsesTheSpanishTexts', () {
    // given
    const stone = Resource.stone;

    // when
    final texts = [
      Internationalize.forestAmount(resource: stone, amount: 3),
      Internationalize.forestMessageStoneGained(amount: 8),
      Internationalize.forestFloatingWoodGained(wood: 5),
      Internationalize.forestFloatingStoneGained(amount: 8),
      Internationalize.forestStock,
      Internationalize.forestQuestsDone(count: 1),
      Internationalize.forestQuestsDone(count: 3),
    ];

    // then
    expect(texts, [
      '3 de piedra',
      '+8 de piedra',
      '+5',
      '+8',
      'Almacén',
      '1 hecha',
      '3 hechas',
    ]);
  });

  test('testWhenExplainingEveryPlacementRejectionThenUsesTheSpanishTexts', () {
    // given
    const rejections = ConstructionRejection.values;

    // when
    final texts = rejections.map((rejection) => Internationalize.forestPlacementRejection(rejection: rejection));

    // then
    expect(texts, [
      'No tienes recursos suficientes.',
      'Ahí no cabe. Busca un sitio despejado.',
    ]);
  });

  test('testWhenNamingTheWorkshopAndItsUpgradesThenUsesTheSpanishTexts', () {
    // given
    const percent = 40;

    // when
    final texts = [
      Internationalize.forestWorkshop,
      Internationalize.forestUpgradeTitle,
      for (final id in UpgradeId.values) Internationalize.forestUpgradeName(id: id),
      for (final id in UpgradeId.values) Internationalize.forestUpgradeEffect(id: id, percent: percent),
      Internationalize.forestUpgradeOwned,
      Internationalize.forestUpgradeNeedsWorkshop,
      Internationalize.forestMessageUpgradePurchased(name: Internationalize.forestUpgradeName(id: UpgradeId.ironAxe)),
      Internationalize.forestMessageUpgradeOwned,
    ];

    // then
    expect(texts, [
      'Taller',
      'Mejoras de herramientas',
      'Hacha de hierro',
      'Pico de hierro',
      'Talas con un 40 % menos de golpes',
      'Picas con un 40 % menos de golpes',
      'Comprada',
      'Construye el Taller',
      'Has mejorado tu herramienta: Hacha de hierro',
      'Ya tienes esa mejora.',
    ]);
  });

  test('testWhenReadingTheGameTextsThenUsesTheSpanishTexts', () {
    // given
    const reason = 'versión 9';

    // when
    final texts = [
      Internationalize.forestGame,
      Internationalize.forestGameSave,
      Internationalize.forestGameSaved,
      Internationalize.forestGameNewGame,
      Internationalize.forestGameNewGameConfirm,
      Internationalize.forestGameConfirm,
      Internationalize.forestGameCancel,
      Internationalize.errorInvalidSaveTitle,
      Internationalize.errorInvalidSaveMessage(reason: reason),
    ];

    // then
    expect(texts, [
      'Partida',
      'Guardar',
      'Partida guardada',
      'Nueva partida',
      'Se perderá la partida actual. ¿Empezar de nuevo?',
      'Empezar',
      'Cancelar',
      'Partida guardada no válida',
      'La partida guardada no es válida: versión 9',
    ]);
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
      Internationalize.forestHeroChampion,
      Internationalize.forestHeroAttack,
      Internationalize.forestHeroDefense,
      Internationalize.forestHeroHealth,
      Internationalize.forestHeroAttackRange(min: 6, max: 8),
      Internationalize.forestHeroWeaponStats(min: 6, max: 8),
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
      'Campeón de la arena',
      'Ataque',
      'Defensa',
      'Vida',
      '6–8',
      'Ataque 6–8',
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
    final descriptions = [
      for (final id in SkillId.values)
        for (var level = 1; level <= 3; level++) Internationalize.forestSkillDescription(id: id, level: level),
    ];

    // then
    expect(names, ['Golpe doble', 'Segundo aliento', 'Esquiva']);
    expect(descriptions, [
      'Cada tercer ataque golpea dos veces.',
      'Cada tercer ataque golpea dos veces y el segundo golpe hace un 15 % más de daño.',
      'Cada tercer ataque golpea dos veces y el segundo golpe hace un 30 % más de daño.',
      'Una vez por pelea, por debajo del 30 % de vida recupera el 40 %.',
      'Una vez por pelea, por debajo del 30 % de vida recupera el 50 %.',
      'Una vez por pelea, por debajo del 30 % de vida recupera el 60 %.',
      'Un 20 % de posibilidades de esquivar cada golpe.',
      'Un 25 % de posibilidades de esquivar cada golpe.',
      'Un 30 % de posibilidades de esquivar cada golpe.',
    ]);
  });

  test('testWhenReadingEverySkillTextThenNoneFallsBackToItsKey', () {
    // given
    final texts = [
      Internationalize.forestHeroLearn,
      Internationalize.forestHeroUpgrade,
      Internationalize.forestHeroSkillMax,
      Internationalize.forestHeroSkillLevel(level: 2, max: 3),
      Internationalize.forestHeroSkillNext(
        level: 3,
        effect: Internationalize.forestSkillDescription(id: SkillId.dodge, level: 3),
      ),
      Internationalize.forestHeroNeedsBuilding(name: Internationalize.forestBlueprint(id: BlueprintId.mageTower)),
      Internationalize.forestMessageSkillLearned(name: Internationalize.forestSkillName(id: SkillId.doubleStrike)),
      Internationalize.forestMessageSkillUpgraded(name: Internationalize.forestSkillName(id: SkillId.dodge), level: 2),
      Internationalize.forestMessageSkillMaxLevel,
    ];

    // when
    final untranslated = texts.where((text) => text.startsWith('forest.')).toList();

    // then
    expect(untranslated, isEmpty);
    expect(texts, [
      'Aprender',
      'Mejorar',
      'Máximo',
      'Nv 2/3',
      'Nv 3: Un 30 % de posibilidades de esquivar cada golpe.',
      'Construye la Torre de magia',
      'Has aprendido: Golpe doble',
      'Has mejorado: Esquiva (Nv 2)',
      'Esa habilidad ya está al nivel máximo.',
    ]);
  });

  test('testWhenFormattingArenaNumbersThenUsesTheSpanishTexts', () {
    // given
    const amounts = FundsMock.tenGold;

    // when
    final reward = Internationalize.arenaReward(amounts: amounts);
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

  test('testWhenFormattingAnArenaRewardThenListsEveryPositiveAmountInResourceOrder', () {
    // given
    const goldAndMana = FundsMock.banditTrioReward;

    // when
    final both = Internationalize.arenaReward(amounts: goldAndMana);
    final withoutZeros = Internationalize.arenaReward(amounts: FundsMock.tenGoldAndZeroMana);
    final reordered = Internationalize.arenaReward(amounts: FundsMock.sixManaBeforeTwentyFiveGold);

    // then
    expect(both, '+75 de oro, 20 de maná');
    expect(withoutZeros, '+10 de oro');
    expect(reordered, '+25 de oro, 6 de maná');
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
      'Lobo',
      'Pareja de lobos',
      'Oso',
      'Manada de lobos',
    ]);
    expect(enemies, ['Bandido', 'Bárbaro', 'Jefe bárbaro', 'Lobo', 'Oso', 'Bandido veterano']);
    expect(advice, [
      '¡Casi lo tienes! Vuelve a intentarlo.',
      'Te falta Ataque: visita la Herrería.',
      'Te falta Defensa: visita la Armería.',
    ]);
    expect((Internationalize.arenaFight, Internationalize.arenaVictory), ('Empezar pelea', '¡Victoria!'));
    expect(Internationalize.arenaChampion, '¡Campeón de la arena!');
  });

  test('testWhenASkillIsUsedInTheArenaThenItsNameIsShouted', () {
    // given
    // when
    final shouts = SkillId.values.map((id) => Internationalize.arenaSkillUsed(id: id)).toList();

    // then
    expect(shouts, ['¡Golpe doble!', '¡Segundo aliento!', '¡Esquiva!']);
  });
}
