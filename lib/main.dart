import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';

class SpaceShooterGame extends FlameGame with PanDetector {
  late Player player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    player = Player()
      ..position = size / 2
      ..width = 25
      ..height = 50
      ..anchor = Anchor.center;

    add(player);
  }

  @override
  void onPanStart(DragStartInfo info) {
    // No movement on initial touch
    player.setVelocity(Vector2.zero());
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    // Get drag delta
    final delta = info.delta.global;
    final speed = 50.0; // Pixels per second

    // Determine primary direction based on largest delta
    if (delta.x.abs() > delta.y.abs()) {
      // Horizontal movement
      if (delta.x < 0) {
        player.setVelocity(Vector2(-speed, 0)); // Left
      } else if (delta.x > 0) {
        player.setVelocity(Vector2(speed, 0)); // Right
      }
    } else {
      // Vertical movement
      if (delta.y < 0) {
        player.setVelocity(Vector2(0, -speed)); // Up
      } else if (delta.y > 0) {
        player.setVelocity(Vector2(0, speed)); // Down
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    player.setVelocity(Vector2.zero()); // Stop moving when drag ends
  }
}

class Player extends PositionComponent {
  static final _paint = Paint()..color = Colors.white;
  Vector2 velocity = Vector2.zero();

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), _paint);
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt; // Move based on velocity over time
  }

  void setVelocity(Vector2 newVelocity) {
    velocity = newVelocity;
  }
}

void main() {
  runApp(GameWidget(game: SpaceShooterGame()));
}