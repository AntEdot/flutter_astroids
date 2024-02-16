import 'dart:async';
import 'dart:developer';
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
  var frictionFactor = Vector2(0.999, 0.999);
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

  bool isShooting = false;

  shoot() {
    game.add(Bullet(position: getBulletSpawnPos(), angle: angle - math.pi, speed: game.bulletSpeed));
    game.score--;
  }

  bool shotgunLoading = false;

  _ss() {
    for (var i = 0; i < game.bullets; i++) {
      game.add(Bullet(
          position: getBulletSpawnPos(),
          angle: angle - math.pi - (((i + 1) ~/ 2) * (game.bulletSpeed / 360) / (2 * math.pi) * (i % 2 == 0 ? 1 : -1)),
          speed: game.bulletSpeed));
    }
  }

  shotgunShot() {
    if (shotgunLoading) return;
    shotgunLoading = true;

    for (var i = 0; i < game.bullets; i++) {
      game.add(Bullet(
          position: getBulletSpawnPos(),
          angle: angle -
              math.pi -
              (((i + 1) ~/ 2) *
                  (game.bulletSpeed / 360) /
                  (2 * math.pi) *
                  (i % 2 == 0 ? 1 : -1) *
                  (math.Random().nextDouble() - 0.5)),
          speed: game.bulletSpeed));
    }

    velocity -= Vector2(math.cos(angle - math.pi), math.sin(angle - math.pi))
      ..scale(2000)
      ..rotate(math.pi / 2);
    frictionFactor = Vector2(0.8, 0.8);
    game.score--;

    Future.delayed(const Duration(milliseconds: 50), () => frictionFactor = Vector2(0.999, 0.999));
    Future.delayed(const Duration(milliseconds: 1000), () => shotgunLoading = false);
  }

  bool turningRight = false, turningLeft = false;

  @override
  bool onKeyEvent(RawKeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    turningLeft = (keysPressed.contains(LogicalKeyboardKey.keyA) || keysPressed.contains(LogicalKeyboardKey.arrowLeft));
    turningRight =
        (keysPressed.contains(LogicalKeyboardKey.keyD) || keysPressed.contains(LogicalKeyboardKey.arrowRight));

    if (!isShooting && keysPressed.contains(LogicalKeyboardKey.keyZ)) {
      timeCounter += 1 / game.attackSpeed;
    }
    isShooting = keysPressed.contains(LogicalKeyboardKey.keyZ);

    if (keysPressed.contains(LogicalKeyboardKey.keyX) || keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      current = PlayerState.accelerating;
    } else {
      current = PlayerState.none;
    }

    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      shotgunShot();
      //game.add(Mine(position: position));
      //game.add(ScoreNumber(value: -10, position: position));
    }

    return true;
  }

  double timeCounter = 0;

  @override
  void update(double dt) {
    timeCounter += dt;

    if (timeCounter > 1 / game.attackSpeed) {
      timeCounter -= 1 / game.attackSpeed;
      if (isShooting) shoot();
    }

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
    required this.speed,
    required this.angle,
  }) : super(size: Vector2(7, 7), anchor: Anchor.center);

  final double angle;
  final double speed;

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

    v = Vector2(math.cos(angle), math.sin(angle))
      ..rotate(math.pi / 2)
      ..scale(game.bulletSpeed);
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
      game.add(BombExploded(position: position, size: Vector2(100, 100)));
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
    Future.delayed(const Duration(milliseconds: 400)).then((value) => removeFromParent());
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, _paint);
  }

  double delta = 20;

  @override
  void update(double dt) {
    super.update(dt);
    delta -= delta * delta * dt;
    delta = delta.clamp(0, 100);
    size += Vector2(delta, delta);
  }
}
