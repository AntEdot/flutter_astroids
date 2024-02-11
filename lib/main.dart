import 'dart:developer';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_astroids/game.dart';

// https://docs.flame-engine.org/latest/tutorials/space_shooter/step_1.html

void main() {
  runApp(const MainWidget());
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  SpaceShooterGame game = SpaceShooterGame();

  restart() => setState(() => game = SpaceShooterGame());

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Colors.black,
        body: GameWidget(
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
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(60),
                          child: Row(
                            children: [
                              TextButton(
                                onPressed: restart,
                                child: const Text('Restart'),
                              ),
                              const Expanded(
                                child: SizedBox(
                                  height: 100,
                                  child: ReactiveText(
                                    'ohjhjhsfgdkfghfdgbkfdg',
                                    maxLines: 1,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 40),
                                  ),
                                ),
                              )
                            ],
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
    );
  }
}

class ReactiveText extends StatelessWidget {
  const ReactiveText(this.text,
      {super.key,
      this.style,
      this.maxLines,
      this.maxHeight,
      this.shouldRender});

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final double? maxHeight;

  final bool Function(bool didExceedMaxLines, bool didExceedMaxHeight)?
      shouldRender;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ReactiveTextPainter(
        text: text,
        style: style,
        maxLines: maxLines,
        maxHeight: maxHeight,
        shouldRender: shouldRender ??
            (didExceedMaxLines, didExceedMaxHeight) =>
                !didExceedMaxLines && !didExceedMaxHeight,
      ),
    );
  }
}

class ReactiveTextPainter extends CustomPainter {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final double? maxHeight;

  final bool Function(bool didExceedMaxLines, bool didExceedMaxHeight)
      shouldRender;

  ReactiveTextPainter({
    super.repaint,
    required this.text,
    this.style,
    this.maxLines,
    this.maxHeight,
    required this.shouldRender,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(text: text, style: style);

    final textPainter = TextPainter(
      text: textSpan,
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );

    log(textPainter.height.toString());

    if (shouldRender(textPainter.didExceedMaxLines,
        textPainter.height > (maxHeight ?? size.height))) {
      final xCenter = (size.width - textPainter.width) / 2;
      final yCenter = (size.height - textPainter.height) / 2;
      final offset = Offset(xCenter, yCenter);

      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(ReactiveTextPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(ReactiveTextPainter oldDelegate) => false;
}
