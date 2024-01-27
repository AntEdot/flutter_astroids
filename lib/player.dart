import 'dart:async';
import 'dart:math' as math;

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_astroids/game.dart';

enum PlayerState {
  none,
  accelerating,
}

class Player extends SpriteGroupComponent<PlayerState> with KeyboardHandler, HasGameRef<SpaceShooterGame> {
  final acceleration = 500.0;
  final frictionFactor = Vector2(0.999, 0.999);
  final maxVelocity = Vector2(500, 500);
  final int turningSpeed = 200;

  Vector2 velocity = Vector2.zero();

  Player() : super(size: Vector2(35, 50), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprites = {
      PlayerState.none: await gameRef.loadSprite('player/player.png'),
      PlayerState.accelerating: await gameRef.loadSprite('player/player-moving.png'),
    };
    current = PlayerState.none;
    position = gameRef.size / 2;

    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  Vector2 getBulletSpawnPos() {
    var v = Vector2(math.cos(angle - math.pi), math.sin(angle - math.pi))
      ..rotate(math.pi / 2)
      ..scale(width / 2 + 1);
    return position + v;
  }

  startShoot() {
    if (!game.bulletSpawner.timer.isRunning()) {
      game.add(Bullet(position: getBulletSpawnPos(), playerAngle: angle));
      game.bulletSpawner.timer.start();
      game.score--;
    }
  }

  stopShoot() {
    game.bulletSpawner.timer.stop();
  }

  bool turningRight = false, turningLeft = false;

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    turningLeft = (keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft));
    turningRight =
        (keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight));

    if (keysPressed.contains(LogicalKeyboardKey.keyZ)) {
      startShoot();
    } else {
      stopShoot();
    }

    if (keysPressed.contains(LogicalKeyboardKey.keyX) || keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      current = PlayerState.accelerating;
    } else {
      current = PlayerState.none;
    }

    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      game.add(Mine(position: position));
      game.add(ScoreNumber(value: -10, position: position));
    }

    return true;
  }

  @override
  void update(double dt) {
    if (turningLeft) {
      angle -= turningSpeed * dt / 180.0 * math.pi;
    }

    if (turningRight) {
      angle += turningSpeed * dt / 180.0 * math.pi;
    }

    if (current == PlayerState.accelerating) {
      Vector2 delta = Vector2(math.cos(angle - math.pi), math.sin(angle - math.pi))
        ..scale(acceleration)
        ..rotate(math.pi / 2);
      velocity += delta * dt;
      velocity.clamp(-maxVelocity, maxVelocity);
    }
    velocity.multiply(frictionFactor);
    position += velocity * dt;

    if (position.x > game.size.x) {
      position.x = 0;
    }

    if (position.x < 0) {
      position.x = game.size.x;
    }

    if (position.y > game.size.y) {
      position.y = 0;
    }

    if (position.y < 0) {
      position.y = game.size.y;
    }

    super.update(dt);
  }
}

class Bullet extends SpriteComponent with HasGameReference<SpaceShooterGame> {
  Bullet({
    super.position,
    required this.playerAngle,
  }) : super(size: Vector2(7, 7), anchor: Anchor.center);

  final double playerAngle;
  late Vector2 v;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    sprite = await game.loadSprite('bullet.png');

    add(
      RectangleHitbox(
        collisionType: CollisionType.passive,
      ),
    );

    v = Vector2(math.cos(playerAngle - math.pi), math.sin(playerAngle - math.pi))
      ..rotate(math.pi / 2)
      ..scale(500);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += v * dt;

    if (position.y > game.size.y || position.x > game.size.x || position.x < 0 || position.y < 0) {
      removeFromParent();
    }
  }
}

class Mine extends PositionComponent with HasGameReference<SpaceShooterGame> {
  static final _paint = Paint()..color = Colors.white;

  Mine({
    super.position,
    super.size,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    Future.delayed(const Duration(milliseconds: 1000)).then((value) {
      removeFromParent();
      game.add(BombExploded(position: position, size: Vector2(300, 300)));
      game.add(BombExploded(position: position, size: Vector2(500, 500)));
    });
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 4, _paint);
  }
}

class BombExploded extends PositionComponent with HasGameReference<SpaceShooterGame> {
  static final _paint = Paint()..color = Colors.white;

  BombExploded({
    super.position,
    super.size,
  }) : super(anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(CircleHitbox(collisionType: CollisionType.passive));
    Future.delayed(const Duration(milliseconds: 120)).then((value) => removeFromParent());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, _paint);
  }
}
