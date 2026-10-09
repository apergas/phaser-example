import 'package:flame/components.dart';
import 'package:flame_bloc/flame_bloc.dart';

import '../bloc/arena_bloc.dart';
import 'arena_scene_component.dart';

class ArenaStateListener extends Component with FlameBlocListenable<ArenaBloc, ArenaState> {
  final ArenaSceneComponent _scene;

  ArenaStateListener({required this._scene});

  @override
  void onInitialState(ArenaState state) {
    _scene.show(state.data);
  }

  @override
  void onNewState(ArenaState state) {
    _scene.show(state.data);
  }
}
