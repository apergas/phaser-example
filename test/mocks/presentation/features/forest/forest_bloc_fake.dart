import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg/layers/presentation/features/forest/bloc/forest_bloc.dart';

class ForestBlocFake extends Bloc<ForestEvent, ForestState> implements ForestBloc {
  final List<ForestEvent> events = [];

  ForestBlocFake(super.initialState) {
    on<ForestEvent>((event, emit) => events.add(event));
  }

  void push(ForestState state) => emit(state);
}
