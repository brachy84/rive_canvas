library rive_canvas;

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
// ignore: implementation_imports
import 'package:rive/src/rive_core/math/aabb.dart';
// ignore: implementation_imports
import 'package:rive/src/rive_core/math/mat2d.dart';
// ignore: implementation_imports
import 'package:rive/src/rive_core/math/vec2d.dart';

/// Use this as a painter in a [CustomPaint] Widget
///
/// ! Note !
/// ! It is very important that you provide a size to the [CustomPaint] Widget
class RivePainter extends CustomPainter {
  /// The file to draw on the canvas
  RiveFile riveFile;

  /// If this is non Null, this will be drawn instead of [riveFile.mainArtboard]
  final String artboardName;

  /// If the [animationController] is non Null it will be automatically animated
  /// FIXME: animation doesn't work
  final RiveAnimationController animationController;

  /// Should a Box with half opacity be painted on top of the artboard
  /// ! not yet implemented
  bool paintHitBox;

  /// The alignment of the artboard in the canvas
  final Alignment alignment;

  /// How the artboard shoud fit in the canvas
  final BoxFit fit;

  Size size;

  Rive riveWidget;
  RiveRenderObject _renderObject;
  RiveCanvas riveCanvas;
  Artboard _artboard;

  RivePainter(this.riveFile,
      {this.artboardName,
      this.animationController,
      //this.paintHitBox = false,
      this.alignment = Alignment.center,
      this.fit = BoxFit.contain}) {
    assert(riveFile != null);
    //assert(paintHitBox != null);
    assert(alignment != null);
    assert(fit != null);
    _init();
  }

  /* // Not ready
  RivePainter.fromPath(String path,
      {this.artboardName,
      this.animationController,
      this.paintHitBox = true,
      this.alignment = Alignment.center,
      this.fit = BoxFit.contain}) {
    assert(path != null);
    assert(paintHitBox != null);
    assert(alignment != null);
    assert(fit != null);
    rootBundle.load(path).then((data) {
      riveFile = RiveFile()..import(data);
      _init();
    });
  }*/

  void _init() {
    if (artboardName != null) {
      _artboard = riveFile.artboardByName(artboardName);
      assert(
          _artboard != null, 'No Artboard was found with name $artboardName');
    } else {
      _artboard = riveFile.mainArtboard;
    }

    riveWidget = Rive(
      artboard: _artboard,
      alignment: alignment,
      fit: fit,
    );
    _renderObject = riveWidget.createRenderObject(null);
    riveCanvas = RiveCanvas(
      renderObject: _renderObject,
    );

    _artboard.advance(0);
    if (animationController != null) {
      _artboard.addController(animationController);
      animationController.isActive = true;
    }
  }

  bool loaded() => riveFile != null && _renderObject != null;

  @override
  void paint(Canvas canvas, Size size) async {
    while (!loaded()) {
      await Future.delayed(Duration(milliseconds: 1));
    }
    if (size == Size.zero) {
      print('#####################################################');
      print('# Warning: size on Custom Paint is Zero             #');
      print('# Rive will not be visible                          #');
      print('# Please provide a size to the CustomPaint widget   #');
      print('#####################################################');
    }
    canvas.drawRive(riveCanvas, size);

    //if (paintHitBox) {
    //  canvas.drawRect(Rect.fromLTWH(0, 0, _artboard.width, _artboard.height),
    //      Paint()..color = Colors.blue.withOpacity(0.5));
    //}
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
    if (oldDelegate is RivePainter) {
      if (!oldDelegate.loaded() && loaded()) {
        return true;
      }
    }
    return false;
  }
}

/// adding a method to [Canvas] for convenience
extension CanvasExtension on Canvas {
  void drawRive(RiveCanvas riveCanvas, Size size) {
    riveCanvas.paint(this, size);
  }
}

/// A helper class to paint a rive on a canvas
class RiveCanvas {
  AABB _bounds;
  Alignment _alignment;
  BoxFit _fit;
  final RiveRenderObject renderObject;

  RiveCanvas({
    @required this.renderObject,
  }) {
    assert(renderObject != null);
    _bounds = renderObject.aabb;
    _alignment = renderObject.alignment;
    _fit = renderObject.fit;
  }

  void paint(Canvas c, Size size) {
    assert(renderObject != null);
    final position = Offset.zero;

    final contentWidth = _bounds[2] - _bounds[0];
    final contentHeight = _bounds[3] - _bounds[1];
    final x = -1 * _bounds[0] -
        contentWidth / 2.0 -
        (_alignment.x * contentWidth / 2.0);
    final y = -1 * _bounds[1] -
        contentHeight / 2.0 -
        (_alignment.y * contentHeight / 2.0);

    double scaleX = 1.0, scaleY = 1.0;

    c.save();
    // pre paint
    //if (shouldClip) {
    c.clipRect(position & size);
    //}

    // boxfit
    switch (_fit) {
      case BoxFit.fill:
        scaleX = size.width / contentWidth;
        scaleY = size.height / contentHeight;
        break;
      case BoxFit.contain:
        double minScale =
            min(size.width / contentWidth, size.height / contentHeight);
        scaleX = scaleY = minScale;
        break;
      case BoxFit.cover:
        double maxScale =
            max(size.width / contentWidth, size.height / contentHeight);
        scaleX = scaleY = maxScale;
        break;
      case BoxFit.fitHeight:
        double minScale = size.height / contentHeight;
        scaleX = scaleY = minScale;
        break;
      case BoxFit.fitWidth:
        double minScale = size.width / contentWidth;
        scaleX = scaleY = minScale;
        break;
      case BoxFit.none:
        scaleX = scaleY = 1.0;
        break;
      case BoxFit.scaleDown:
        double minScale =
            min(size.width / contentWidth, size.height / contentHeight);
        scaleX = scaleY = minScale < 1.0 ? minScale : 1.0;
        break;
    }

    final transform = Mat2D();
    transform[4] = size.width / 2.0 + (_alignment.x * size.width / 2.0);
    transform[5] = size.height / 2.0 + (_alignment.y * size.height / 2.0);
    Mat2D.scale(transform, transform, Vec2D.fromValues(scaleX, scaleY));
    final center = Mat2D();
    center[4] = x;
    center[5] = y;
    Mat2D.multiply(transform, transform, center);

    c.translate(
      size.width / 2.0 + (_alignment.x * size.width / 2.0),
      size.height / 2.0 + (_alignment.y * size.height / 2.0),
    );

    c.scale(scaleX, scaleY);
    c.translate(x, y);

    renderObject.draw(c, transform);
    c.restore();
    // literally does nothing
    //_renderObject.postPaint(c, position);
  }
}
