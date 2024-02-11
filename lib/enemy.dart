import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter_astroids/game.dart';
import 'package:flutter_astroids/player.dart';

enum EnemyAstroidType {
  small,
  big,
}

enum EnemyAstroidSprites {
  small,
  big_0,
  big_1,
  big_2,
}

class Enemy extends SpriteGroupComponent<EnemyAstroidSprites>
    with HasGameReference<SpaceShooterGame>, CollisionCallbacks {
  final EnemyAstroidType type;

  Enemy({required this.type, super.position, super.size})
      : super(
          anchor: Anchor.center,
        );

  late Vector2 velocity;

  bool get isSmall => type == EnemyAstroidType.small;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    int variant = Random().nextInt(3);

    sprites = {
      EnemyAstroidSprites.small: await game.loadSprite('enemies/astroid-small-$variant-0.png'),
      EnemyAstroidSprites.big_0: await game.loadSprite('enemies/astroid-big-$variant-0.png'),
      EnemyAstroidSprites.big_1: await game.loadSprite('enemies/astroid-big-$variant-1.png'),
      EnemyAstroidSprites.big_2: await game.loadSprite('enemies/astroid-big-$variant-2.png'),
    };

    current = isSmall ? EnemyAstroidSprites.small : EnemyAstroidSprites.big_0;

    final Vector2 maxVelocity = Vector2(isSmall ? 180 : 90, isSmall ? 180 : 90);
    final Vector2 minVelocity = Vector2(10, 10);

    Vector2 v = Vector2.random();
    v.multiply(maxVelocity * 2);
    v.sub(maxVelocity);
    v.add(minVelocity);

    velocity = v;

    add(CircleHitbox());
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);

    if (other is Bullet || other is BombExploded) {
      if (isSmall || current == EnemyAstroidSprites.big_2) {
        removeFromParent();
        if (current == EnemyAstroidSprites.big_2) {
          for (var i = 0; i < Random().nextInt(3) + 1; i++) {
            game.add(Enemy(position: position, size: Vector2(50, 50), type: EnemyAstroidType.small));
          }
        }
      } else {
        current = EnemyAstroidSprites.values[(current?.index ?? 0) + 1];
      }

      if (other is Bullet) other.removeFromParent();
      game.add(ScoreNumber(value: 5, position: position));
    }

    if (other is Player) {
      removeFromParent();
      game.health--;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    position.x += dt * velocity.x;
    position.y += dt * velocity.y;

    if (position.x > game.size.x + size.x / 2) {
      position.x = -size.x / 2;
    }

    if (position.x < -size.x / 2) {
      position.x = game.size.x + size.x / 2;
    }

    if (position.y > game.size.y + size.y / 2) {
      position.y = -game.size.y;
    }

    if (position.y < -size.y / 2) {
      position.y = game.size.y + size.y / 2;
    }
  }
}
