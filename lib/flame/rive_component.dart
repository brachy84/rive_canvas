import 'package:flame/components/component.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

import 'package:rive_canvas/rive_canvas.dart';

/// A PositionComponent that renders a [Artboard] from a [RiveFile]
/// make sure to to call super... when overriding a method
class RiveComponent extends PositionComponent {
  /// The file to draw on the canvas
  RiveFile riveFile;

  /// If this is non Null, this will be drawn instead of [riveFile.mainArtboard]
  final String artboardName;

  /// If the [animationController] is non Null it will be automatically animated
  final RiveAnimationController animationController;

  /// How the artboard shoud fit in the canvas
  /// default is [BoxFit.contain]
  final BoxFit fit;

  /// Alignment of the artboard in the canvas.
  /// ! Can be a bit wonky in combination with scale
  /// or some [BoxFit]
  final Alignment alignment;

  /// By default the size is the size of the artboard.
  /// If this is changed, the artboard dimensions stays the same.
  /// If one dimension is < 0 or == [double.infinity]
  /// the dimension will be set to the artboards dimension
  Size _size;

  /// How much should the size be scaled.
  /// This will not scale the canvas, but rather
  /// the width and height of
  double _scale;

  RiveRenderObject _renderObject;
  RiveCanvas _riveCanvas;
  Artboard artboard;
  final _pipelineOwner = _RiveComponentPipelineOwner();

  /// Use this if you have multiple components that use
  /// the same rive to reduce loading time;
  RiveComponent(this.riveFile,
      {this.artboardName,
      this.animationController,
      Size size,
      double scale,
      this.alignment = Alignment.center,
      this.fit = BoxFit.contain}) {
    assert(riveFile != null && fit != null);
    _init();
    _initSizeAndScale(size, scale);
  }

  RiveComponent.fromPath(String filePath,
      {this.artboardName,
      this.animationController,
      Size size,
      double scale,
      this.alignment = Alignment.center,
      this.fit = BoxFit.contain}) {
    rootBundle.load(filePath).then((data) {
      riveFile = RiveFile()..import(data);
      _init();
      _initSizeAndScale(size, scale);
    });
  }

  void _init() {
    // init artboard
    if (artboardName != null) {
      artboard = riveFile.artboardByName(artboardName);
      assert(artboard != null, 'No Artboard was found with name $artboardName');
    } else {
      artboard = riveFile.mainArtboard;
    }

    _renderObject = RRO.of(this);
    _riveCanvas = RiveCanvas.fromComponent(this);

    // init animation
    if (animationController != null) {
      artboard.addController(animationController);
    }
  }

  void _initSizeAndScale(Size size, double scale) {
    if (size != null) {
      if (size.width == double.infinity || size.width < 0) {
        size = Size(artboard.width, size.height);
      }
      if (size.height == double.infinity || size.height < 0) {
        size = Size(size.width, artboard.height);
      }
      canvasSize = size;
    } else {
      canvasSize = Size(artboard.width, artboard.height);
    }
    if (scale != null) {
      this.scale = scale;
    }
  }

  @override
  bool loaded() => riveFile != null && _renderObject != null;

  bool isPlaying() => animationController?.isActive ?? false;

  /// getter and setter for [_size]
  Size get canvasSize => _size;
  set canvasSize(Size value) {
    _size = value;
    updateWidthHeight();
  }

  /// getter and setter for [_scale]
  double get scale => _scale;
  set scale(double value) {
    _scale = value;
    _size = Size(_size.width * _scale, _size.height * _scale);
    updateWidthHeight();
  }

  /// called when [_size] or [_scale] change
  void updateWidthHeight() {
    width = canvasSize.width;
    height = canvasSize.height;
  }

  /// starts the animation if a [animationController] is Provided
  void startAnimation() {
    if (animationController != null && !animationController.isActive) {
      animationController.isActive = true;
    }
  }

  /// stops the animation if a [animationController] is Provided
  void stopAnimation() {
    if (animationController != null && animationController.isActive) {
      animationController.isActive = false;
    }
  }

  @mustCallSuper
  @override
  void onMount() async {
    super.onMount();
    while (!loaded()) {
      await Future.delayed(Duration(milliseconds: 1));
    }
    _renderObject.attach(_pipelineOwner);
    artboard.advance(0);
    startAnimation();
  }

  @mustCallSuper
  @override
  void render(Canvas canvas) {
    prepareCanvas(canvas);
    _riveCanvas.draw(canvas, canvasSize, scale: scale);
  }

  @mustCallSuper
  @override
  void update(double dt) {
    super.update(dt);
    if (!loaded()) return;
    _renderObject.advance(dt);
  }

  @mustCallSuper
  @override
  void onDestroy() {
    stopAnimation();
    _renderObject.dispose();
    super.onDestroy();
  }
}

class _RiveComponentPipelineOwner extends PipelineOwner {}

extension RRO on RiveRenderObject {
  static RiveRenderObject of(RiveComponent component) {
    return Rive(
            artboard: component.artboard,
            alignment: component.alignment,
            fit: component.fit)
        .createRenderObject(null);
  }
}
