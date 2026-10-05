import 'package:flame/components.dart';

class UpdateProbeComponentFake extends Component {
  final List<double> updates = [];

  @override
  void update(double dt) {
    updates.add(dt);
  }
}
