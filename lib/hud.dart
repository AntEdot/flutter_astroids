import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_astroids/game.dart';

class HealthComponent extends SpriteComponent with HasGameReference<SpaceShooterGame> {
  int index;

  HealthComponent({
    required this.index,
    required super.position,
    required super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.priority,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await game.loadSprite(
      'player/player.png',
    );
  }

  @override
  void update(double dt) {
    if (game.health < index) {
      removeFromParent();
    }
  }
}

class Hud extends PositionComponent with HasGameReference<SpaceShooterGame>, KeyboardHandler {
  Hud({
    super.position,
    super.size,
    super.scale,
    super.angle,
    super.anchor,
    super.children,
    super.priority = 5,
  });

  late TextComponent _scoreTextComponent, _difficultyTextComponent;

  @override
  Future<void> onLoad() async {
    _scoreTextComponent = TextComponent(
      text: 'Score: ${game.score}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.topLeft,
      position: Vector2(20, 10),
    );
    add(_scoreTextComponent);

    _difficultyTextComponent = TextComponent(
      text: 'X: ${game.difficulty}',
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 32,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.bottomLeft,
      position: Vector2(20, game.size.y - 10),
    );
    add(_difficultyTextComponent);

    for (var i = 1; i <= game.health; i++) {
      final positionX = 40 * i;
      await add(
        HealthComponent(
          index: i,
          position: game.size - Vector2(positionX.toDouble() + 20, 70),
          size: Vector2(30, 40),
        ),
      );
    }
  }

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.escape)) {
      if (game.paused) {
        game.overlays.remove('pauseMenu');
        game.resumeEngine();
      } else {
        game.overlays.add('pauseMenu');
        game.pauseEngine();
      }
    }

    return true;
  }

  @override
  void update(double dt) {
    _scoreTextComponent.text = 'Score: ${game.score}';
    if (game.health <= 0) {
      game.pauseEngine();
    }

    game.difficulty = (game.score ~/ 100).clamp(1, 20);
    _difficultyTextComponent.text = 'x ${game.difficulty}';

    if (game.paused) {
      game.overlays.add('pauseMenu');
    } else {
      game.overlays.remove('pauseMenu');
    }
  }
}
