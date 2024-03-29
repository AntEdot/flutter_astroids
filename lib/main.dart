import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_astroids/game.dart';
import 'package:window_manager/window_manager.dart';

// https://docs.flame-engine.org/latest/tutorials/space_shooter/step_1.html

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  bool isFullScreen = await windowManager.isFullScreen();
  windowManager.setAspectRatio((isFullScreen ? 1600 : (1600 - 40)) / 900);

  windowManager.setMinimumSize(const Size(1600, 900));

  runApp(const MainWidget());
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> with WindowListener {
  SpaceShooterGame game = SpaceShooterGame();
  bool isFullScreen = false;

  late int as = game.attackSpeed;

  double scale = 1;

  restart() => setState(() => game = SpaceShooterGame());

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    Future.delayed(const Duration(milliseconds: 200), () {
      rescale();
      restart();
    });
    windowManager.isFullScreen().then((value) {
      if (value != isFullScreen) {
        setState(() => isFullScreen = value);
      }
    });
  }

  rescale() {
    Size size = MediaQuery.of(context).size;
    double widthScale = size.width / 1600;
    double heightScale = (size.height) / 900;
    log('${math.min(widthScale, heightScale).clamp(1, 2)} ${MediaQuery.of(context).size}');
    setState(() {
      scale = math.min(widthScale, heightScale).clamp(1, 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Transform.scale(
            scale: scale,
            child: SizedBox(
              height: 900,
              width: 1600,
              child: ClipRRect(
                child: GameWidget(
                  game: game,
                  overlayBuilderMap: {
                    'pauseMenu': (BuildContext context, SpaceShooterGame game) {
                      return ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                          child: Stack(
                            children: [
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        game.health > 0 ? 'Paused' : 'Game over',
                                        style: Theme.of(context).textTheme.displayLarge,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 24),
                                      child: Text(
                                        'Score: ${game.score}',
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ),
                                    if (game.health > 0)
                                      TextButton(
                                        onPressed: () => game.resumeEngine(),
                                        child: const Text('Resume'),
                                      ),
                                    TextButton(
                                      onPressed: restart,
                                      child: const Text('Restart'),
                                    ),
                                    TextButton(
                                      onPressed: () => exit(0),
                                      child: const Text('Exit'),
                                    ),
                                  ],
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: Padding(
                                  padding: const EdgeInsets.all(60),
                                  child: SizedBox(
                                    height: 40,
                                    child: Row(
                                      children: [
                                        TextButton(
                                          onPressed: () async {
                                            windowManager.setAspectRatio((isFullScreen ? 1600 : (1600 - 40)) / 900);
                                            windowManager.setFullScreen(!isFullScreen);
                                            isFullScreen = !isFullScreen;
                                          },
                                          child: Text(isFullScreen ? 'Windowed' : 'Fullscreen'),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(horizontal: 8),
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.speed_rounded),
                                              Slider(
                                                value: game.attackSpeed.toDouble(),
                                                max: 20,
                                                min: 1,
                                                onChanged: (value) {
                                                  setState(() {
                                                    as = value.round();
                                                  });
                                                  game.changeAttackSpeed(value.round());
                                                },
                                              ),
                                              Text(game.attackSpeed.toString()),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowResized() {
    super.onWindowResized();
    rescale();
  }

  @override
  void onWindowMaximize() {
    super.onWindowMaximize();
    Future.delayed(const Duration(milliseconds: 200), rescale);
  }

  @override
  void onWindowUnmaximize() {
    super.onWindowUnmaximize();
    Future.delayed(const Duration(milliseconds: 200), rescale);
  }

  @override
  void onWindowEnterFullScreen() {
    super.onWindowEnterFullScreen();
    Future.delayed(const Duration(milliseconds: 200), rescale);
  }

  @override
  void onWindowLeaveFullScreen() {
    super.onWindowLeaveFullScreen();
    Future.delayed(const Duration(milliseconds: 200), rescale);
  }

  @override
  void onWindowMinimize() {
    super.onWindowMinimize();
    game.overlays.add('pauseMenu');
    game.pauseEngine();
  }
}
