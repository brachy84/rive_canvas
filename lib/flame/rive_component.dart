import 'package:flame/components/component.dart';
import 'package:flame/components/mixins/resizable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';

import 'package:rive_canvas/rive_canvas.dart';

/// A PositionComponent that renders a [Artboard] from a [RiveFile]
/// make sure to to call super... when overriding a method
class RiveComponent extends PositionComponent with Resizable {
  /// The file to draw on the canvas
  RiveFile riveFile;

  /// If this is non Null, this will be drawn instead of [riveFile.mainArtboard]
  final String artboardName;

  /// If the [animationController] is non Null it will be automatically animated
  final RiveAnimationController animationController;

  /// The alignment of the artboard in the canvas
  /// default is [Alignment.center]
  final Alignment alignment;

  /// How the artboard shoud fit in the canvas
  /// default is [BoxFit.contain]
  final BoxFit fit;

  /// If the animation should automatically be startet and stopped
  /// can still be controlled with [startAnimation] and [stopAnimation]
  /// default is true
  final bool autoAnimate;

  Rive riveWidget;
  RiveRenderObject _renderObject;
  RiveCanvas _riveCanvas;
  Artboard _artboard;
  final _pipelineOwner = RiveComponentPipelineOwner();

  RiveComponent(this.riveFile,
      {this.artboardName,
      this.animationController,
      this.alignment = Alignment.center,
      this.fit = BoxFit.contain,
      this.autoAnimate = true}) {
    assert(riveFile != null && alignment != null && fit != null);
    _init();
  }

  RiveComponent.fromPath(String filePath,
      {this.artboardName,
      this.animationController,
      this.alignment = Alignment.center,
      this.fit = BoxFit.contain,
      this.autoAnimate = true}) {
    rootBundle.load(filePath).then((data) {
      riveFile = RiveFile()..import(data);
      _init();
    });
  }

  void _init() {
    // init artboard
    if (artboardName != null) {
      _artboard = riveFile.artboardByName(artboardName);
      assert(
          _artboard != null, 'No Artboard was found with name $artboardName');
    } else {
      _artboard = riveFile.mainArtboard;
    }

    // init render object
    riveWidget = Rive(
      artboard: _artboard,
      alignment: alignment,
      fit: fit,
    );
    _renderObject = riveWidget.createRenderObject(null);
    _riveCanvas = RiveCanvas(
      renderObject: _renderObject,
    );

    // init animation
    if (animationController != null) {
      _artboard.addController(animationController);
    }
  }

  bool get isLoaded => riveFile != null && _renderObject != null;

  bool isPlaying() => animationController?.isActive ?? false;

  /// starts the animation if a [animationController] is Provided
  void startAnimation() {
    if (animationController != null && animationController.isActive) {
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
    if (isLoaded) await Future.delayed(Duration(milliseconds: 1));
    _renderObject.attach(_pipelineOwner);
    _artboard.advance(0);
    if (autoAnimate) {
      startAnimation();
    }
  }

  @mustCallSuper
  @override
  void render(Canvas canvas) {
    prepareCanvas(canvas);
    _riveCanvas.paint(canvas, size);
  }

  @mustCallSuper
  @override
  void update(double dt) {
    super.update(dt);
    _renderObject.advance(dt);
  }

  @mustCallSuper
  @override
  void onDestroy() {
    if (autoAnimate) {
      stopAnimation();
    }
    _renderObject.dispose();
    super.onDestroy();
  }
}

class RiveComponentPipelineOwner extends PipelineOwner {}
