import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/experimental.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_astroids/enemy.dart';
import 'package:flutter_astroids/hud.dart';
import 'package:flutter_astroids/player.dart';

class SpaceShooterGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  late Player player;
  late final SpawnComponent bulletSpawner;

  int score = 0;
  int health = 3;
  int difficulty = 1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    player = Player();
    add(player);

    bulletSpawner = SpawnComponent(
      period: .2,
      selfPositioning: true,
      factory: (index) {
        score--;
        return Bullet(
          position: player.getBulletSpawnPos(),
          playerAngle: player.angle,
        );
      },
      autoStart: false,
    );

    add(bulletSpawner);

    add(
      SpawnComponent(
        factory: (index) {
          return Enemy(type: EnemyAstroidType.big, size: Vector2(150, 150));
        },
        period: 1 / difficulty,
        within: false,
        area: Rectangle.fromLTRB(-48, -48, size.x + 48, size.y + 48),
      ),
    );

    add(Hud());
  }
}

class ScoreNumber extends PositionComponent with HasGameReference<SpaceShooterGame> {
  final int value;
  ScoreNumber({required this.value, super.position}) : super(anchor: Anchor.center);

  @override
  FutureOr<void> onLoad() async {
    await super.onLoad();
    game.score += value;
    add(TextComponent(
      text: '$value',
      textRenderer: TextPaint(
        style: TextStyle(
          fontSize: (value.abs() + 12).clamp(8, 32).toDouble(),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      anchor: Anchor.center,
    ));
    Future.delayed(const Duration(milliseconds: 400)).then((value) => removeFromParent());
  }
}
