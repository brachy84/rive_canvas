# Rive Canvas

A package to make [rive](https://pub.dev/packages/rive) even more great

This package helps rendering Rives on a canvas directly.
It also comes with a RiveComponent for the [Flame game engine](https://pub.dev/packages/flame).

## You can use rive_canvas to:
 
 * draw (currently non animatable) rives directly on a canvas:
 ```dart
canvas.drawStaticRiveRect(riveFile.mainArtboard, Rect.fromLTWH(20, 150, 50, 50));
 ```
 * draw rives as a Component in a [Flame](https://pub.dev/packages/flame) game:
 ```dart
class RiveGame extends BaseGame {
    RiveGame() {
        add(Background());
        add(RiveComponent.fromPath(
            'assets/rive/test.riv', 
            animationController: SimpleAnimation('drip')
       ));
    }
}
 ```
For a more detailed example got to examples or [Github](https://github.com/brachy84/rive_canvas/blob/master/example/lib/rive_component_example.dart) 
  
If you have issues or need help, come to [Github](https://github.com/brachy84/rive_canvas)
