import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../bloc/forest_bloc.dart';
import 'forest_scene_component.dart';

class ForestStateListener extends Component with FlameBlocListenable<ForestBloc, ForestState> {
  final ForestSceneComponent _scene;

  ForestStateListener({required this._scene});

  @override
  void onInitialState(ForestState state) {
    _scene.show(state.data);
  }

  @override
  void onNewState(ForestState state) {
    _scene.show(state.data);
  }
}
