import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rpg/layers/presentation/features/arena/bloc/arena_bloc.dart';

class ArenaBlocFake extends Bloc<ArenaEvent, ArenaState> implements ArenaBloc {
  final List<ArenaEvent> events = [];

  ArenaBlocFake(super.initialState) {
    on<ArenaEvent>((event, emit) => events.add(event));
  }

  void push(ArenaState state) => emit(state);
}
