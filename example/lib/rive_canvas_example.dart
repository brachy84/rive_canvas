import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_canvas/rive_canvas.dart';
import 'package:rive/rive.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: Text('Rive Canvas'),
          ),
          body: HomeScreen()),
    );
  }
}

class HomeScreen extends StatelessWidget {
  RiveFile riveFile;

  Future<void> loadRive() async {
    final data = await rootBundle.load('assets/rive/test.riv');
    riveFile = RiveFile()..import(data);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return FutureBuilder(
        future: loadRive(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              riveFile != null) {
            return Container(
              child: CustomPaint(
                size: screenSize,
                painter: RivePainter(riveFile),
              ),
            );
          }
          return Container();
        });
  }
}
