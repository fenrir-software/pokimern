import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:flame/experimental.dart';

void main() {
  runApp(GameWidget(game: PokimernGame()));
}

class PokimernGame extends FlameGame with PanDetector {
  late Player player;
  late SpriteComponent map;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Load the spritesheet for the player
    try {
      await Flame.images.load('character_base_16x16.png');
    } catch (e) {
      print('Error loading player spritesheet: $e');
    }

    // Load the map PNG
    try {
      await Flame.images.load('tilesheet_basic.png');
    } catch (e) {
      print('Error loading map PNG: $e');
    }

    // Create map as a single sprite
    final mapSprite = await Sprite.load('tilesheet_basic.png');
    const mapWidth = 1280.0; // Adjust to your PNG's width in pixels
    const mapHeight = 1280.0; // Adjust to your PNG's height in pixels
    map = SpriteComponent(
      sprite: mapSprite,
      size: Vector2(mapWidth, mapHeight),
      anchor: Anchor.center, // Center the map's anchor for easier clamping
    );
    // Center the map initially
    map.position = Vector2(mapWidth / 2, mapHeight / 2);
    add(map);

    // Initialize player, centered on screen
    player = Player(game: this)
      ..position = size / 2 // Center of screen
      ..size = Vector2(48, 48) // Sprite size
      ..anchor = Anchor.center;
    add(player);

    // Set camera bounds to cover the entire map
    camera.setBounds(Rectangle.fromLTRB(
      0,
      0,
      mapWidth,
      mapHeight,
    ));
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
    const deadzone = 0.5; // Ignore tiny movements to reduce jitter

    // Skip small movements to prevent jitter
    if (delta.length < deadzone) {
      return;
    }

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
    // Keep player centered
    position = game.size / 2;
    // Move the map opposite to the player's velocity
    final map = (game as PokimernGame).map;
    map.position -= velocity * dt;

    // Clamp map position to keep PNG edges within view
    const mapWidth = 1280.0; // Must match mapWidth in onLoad
    const mapHeight = 1280.0; // Must match mapHeight in onLoad
    final halfScreenWidth = game.size.x / 2;
    final halfScreenHeight = game.size.y / 2;
    final minX = halfScreenWidth - mapWidth / 2;
    final maxX = halfScreenWidth + mapWidth / 2;
    final minY = halfScreenHeight - mapHeight / 2;
    final maxY = halfScreenHeight + mapHeight / 2;
    map.position.x = map.position.x.clamp(minX, maxX);
    map.position.y = map.position.y.clamp(minY, maxY);
  }

  void setVelocity(Vector2 newVelocity) {
    velocity = newVelocity;
  }
}