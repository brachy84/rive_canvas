import 'package:flutter/material.dart';
import 'package:flame/game/base_game.dart';
import 'package:flame/flame.dart';
import 'package:flame/util.dart';
import 'package:flame/components/component.dart';
import 'package:flutter/services.dart';
import 'package:rive_canvas/flame/rive_component.dart';
import 'package:flame/components/mixins/resizable.dart';
import 'package:rive/rive.dart';
import 'dart:ui' as ui;

Size gameSize;

// just a normal main() function for a flame game
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Util flameUtil = Util();
  flameUtil.setOrientations(
      [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
  flameUtil.fullScreen();
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
        child: Container(
            child: Stack(
          children: [
            RiveGame(size: gameSize).widget,
          ],
        )),
      ),
    );
  }
}

class RiveGame extends BaseGame {
  RiveGame({Size size}) {
    this.size = size;
    add(Background());
    // since I don't have any logic in TestRiveComponent, I could just do
    // add(RiveComponent.fromPath('assets/rive/test.riv', animationController: SimpleAnimation('drip')));
    add(TestRiveComponent.fromPath('assets/rive/test.riv', 'drip'));
  }
}

class TestRiveComponent extends RiveComponent {
  TestRiveComponent.fromPath(String filePath, String animation)
      : super.fromPath(filePath,
            animationController: SimpleAnimation(animation));

  // implement more render and update logic
}

class Background extends Component with Resizable {
  @override
  void render(Canvas c) {
    final paint = Paint();
    paint.shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height),
        [Colors.grey[700], Colors.grey[300]]);
    c.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  void update(double t) {}
}
