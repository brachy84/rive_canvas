import 'package:flutter/material.dart';
import 'package:flame/game/base_game.dart';
import 'package:flame/flame.dart';
import 'package:flame/util.dart';
import 'package:rive_canvas/flame/rive_component.dart';

Size gameSize;

// just a normal main() function for a flame game
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Util flameUtil = Util();
  gameSize = await Flame.util.initialDimensions();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rive Canvas Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Material(
        child: RiveGame(size: gameSize).widget,
      ),
    );
  }
}

class RiveGame extends BaseGame {
  RiveGame({Size size}) {
    this.size = size;
    add(TestRiveComponent.fromPath('assets/rive/test.riv'));
  }
}

class TestRiveComponent extends RiveComponent {
  TestRiveComponent.fromPath(String filePath) : super.fromPath(filePath);

  // implement more render and update logic here
}
