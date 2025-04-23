import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';

void main() {
  runApp(GameWidget(game: PokimernGame()));
}

class PokimernGame extends FlameGame with PanDetector {
  late Player player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the spritesheet using Flame.images
    try {
      await Flame.images.load('character_base_16x16.png');
    } catch (e) {
      print('Error loading spritesheet: $e');
    }

    player = Player(game: this) // Fixed: Pass the game instance
      ..position = size / 2
      ..size = Vector2(48, 48) // Sprite size
      ..anchor = Anchor.center;

    add(player);
  }

  @override
  void onPanStart(DragStartInfo info) {
    player.setVelocity(Vector2.zero());
    player.current = PlayerState.idle;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final delta = info.delta.global;
    const speed = 100.0; // Pixels per second

    if (delta.x.abs() > delta.y.abs()) {
      if (delta.x < 0) {
        player.setVelocity(Vector2(-speed, 0)); // Left
        player.current = PlayerState.left;
      } else if (delta.x > 0) {
        player.setVelocity(Vector2(speed, 0)); // Right
        player.current = PlayerState.right;
      }
    } else {
      if (delta.y < 0) {
        player.setVelocity(Vector2(0, -speed)); // Up
        player.current = PlayerState.backward;
      } else if (delta.y > 0) {
        player.setVelocity(Vector2(0, speed)); // Down
        player.current = PlayerState.forward;
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    player.setVelocity(Vector2.zero());
    player.current = PlayerState.idle;
  }
}

enum PlayerState { forward, backward, right, left, idle }

class Player extends SpriteAnimationGroupComponent<PlayerState> {
  Vector2 velocity = Vector2.zero();
  final FlameGame game; // Reference to the game for size access

  Player({required this.game}) : super(size: Vector2(16, 16));

  @override
  Future<void> onLoad() async {
    try {
      // Use Flame.images to access the pre-loaded spritesheet
      final spriteSheet = SpriteSheet(
        image: Flame.images.fromCache('character_base_16x16.png'),
        srcSize: Vector2(16, 16),
      );

      final forwardAnimation = spriteSheet.createAnimation(row: 0, stepTime: 0.2, from: 0, to: 4);
      final backwardAnimation = spriteSheet.createAnimation(row: 1, stepTime: 0.2, from: 0, to: 4);
      final rightAnimation = spriteSheet.createAnimation(row: 2, stepTime: 0.2, from: 0, to: 4);
      final leftAnimation = spriteSheet.createAnimation(row: 3, stepTime: 0.2, from: 0, to: 4);
      final idleAnimation = spriteSheet.createAnimation(row: 0, stepTime: 0.2, from: 0, to: 1);

      animations = {
        PlayerState.forward: forwardAnimation,
        PlayerState.backward: backwardAnimation,
        PlayerState.right: rightAnimation,
        PlayerState.left: leftAnimation,
        PlayerState.idle: idleAnimation,
      };

      current = PlayerState.idle;
    } catch (e) {
      print('Error setting up player animations: $e');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    // Keep player within screen bounds, casting to double
    position.x = position.x.clamp(0.0, game.size.x - size.x).toDouble();
    position.y = position.y.clamp(0.0, game.size.y - size.y).toDouble();
  }

  void setVelocity(Vector2 newVelocity) {
    velocity = newVelocity;
  }
}