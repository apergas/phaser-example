import '../../../../../../core/config/constants/enum/blueprint_id.dart';

abstract final class RenderConstants {
  static const double cameraZoom = 2;

  static const double characterFrameSize = 64;
  static const double characterAnchorY = 62 / 64;
  static const int rowUp = 0;
  static const int rowLeft = 1;
  static const int rowDown = 2;
  static const int rowRight = 3;

  static const int walkColumns = 9;
  static const int walkFirstStep = 1;
  static const int walkLastStep = 8;
  static const double walkFps = 10;

  static const int idleColumns = 2;
  static const double idleFps = 2;

  static const double workFrameSize = 128;
  static const int workColumns = 6;
  static const double workAnchorY = (32 + 62) / 128;
  static const List<int> chopSequence = [0, 0, 5, 5, 4, 4, 3, 1];
  static const List<int> hammerSequence = [0, 0, 5, 5, 4, 4, 1];

  static double buildingFrontOffset(BlueprintId id) => switch (id) {
    BlueprintId.house => 24,
  };

  static const double cameraLerp = 0.1;
  static const double maxFrameSeconds = 0.1;
  static const int backgroundColor = 0xFF0E150E;
  static const int solidAlpha = 200;
}
