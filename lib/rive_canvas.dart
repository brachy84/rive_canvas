library rive_canvas;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive/rive.dart';
import 'package:rive_canvas/flame/rive_component.dart';

/// adding a method to [Canvas] for convenience
extension CanvasExtension on Canvas {
  /// draws a non animatable rive on a canvas
  void drawStaticRiveRect(Artboard artboard, Rect rect) {
    RiveCanvas(artboard: artboard, offset: rect.topLeft).draw(this, rect.size);
  }
}

/// A helper class to paint a rive on a canvas
class RiveCanvas {
  Alignment alignment;
  BoxFit fit;
  Artboard artboard;
  RiveAnimationController animationController;
  RiveRenderObject _renderObject;
  Offset offset;

  RiveCanvas(
      {this.alignment = Alignment.center,
      this.fit = BoxFit.contain,
      @required this.artboard,
      this.animationController,
      this.offset = Offset.zero}) {
    assert(artboard != null);
    _renderObject = Rive(
      artboard: artboard,
      alignment: alignment,
      fit: fit,
    ).createRenderObject(null);
    if (animationController != null) {
      artboard.addController(animationController);

      _renderObject.attach(_RiveComponentPipelineOwner());
    }
  }

  RiveCanvas.fromComponent(RiveComponent component) {
    alignment = component.alignment;
    fit = component.fit;
    artboard = component.artboard;
    offset = Offset.zero;
  }

  double _scaleX = 1.0, _scaleY = 1.0;

  void draw(Canvas canvas, Size size, {double scale = 1}) async {
    _renderObject?.advance(0);
    canvas.save();
    _setBoxFit(canvas, size);
    _setAlignment(canvas, size, scale);
    artboard.draw(canvas);
    canvas.restore();
  }

  void _setAlignment(Canvas canvas, Size size, double scale) {
    double posX, posY, aX, aY;
    double contentWidth = artboard.width;
    double contentHeight = artboard.height;

    aX = alignment.x + ((2 - (alignment.x + 1)) / 2);
    aY = alignment.y + ((2 - (alignment.y + 1)) / 2);

    posX = size.width * aX - contentWidth * _scaleX * aX;
    posY = size.height * aY - contentHeight * _scaleY * aY;

    canvas.translate(posX + offset.dx, posY + offset.dy);
  }

  void _setBoxFit(Canvas canvas, Size size) {
    final contentWidth = artboard.width;
    final contentHeight = artboard.height;
    _scaleX = 1.0;
    _scaleY = 1.0;

    switch (fit) {
      case BoxFit.fill:
        _scaleX = size.width / contentWidth;
        _scaleY = size.height / contentHeight;
        break;
      case BoxFit.contain:
        double minScale =
            min(size.width / contentWidth, size.height / contentHeight);
        _scaleX = _scaleY = minScale;
        break;
      case BoxFit.cover:
        double maxScale =
            max(size.width / contentWidth, size.height / contentHeight);
        _scaleX = _scaleY = maxScale;
        break;
      case BoxFit.fitHeight:
        double minScale = size.height / contentHeight;
        _scaleX = _scaleY = minScale;
        break;
      case BoxFit.fitWidth:
        double minScale = size.width / contentWidth;
        _scaleX = _scaleY = minScale;
        break;
      case BoxFit.none:
        _scaleX = _scaleY = 1.0;
        break;
      case BoxFit.scaleDown:
        double minScale =
            min(size.width / contentWidth, size.height / contentHeight);
        _scaleX = _scaleY = minScale < 1.0 ? minScale : 1.0;
        break;
    }
    canvas.scale(_scaleX, _scaleY);
  }
}

class _RiveComponentPipelineOwner extends PipelineOwner {}
