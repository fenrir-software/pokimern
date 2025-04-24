import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:flame/experimental.dart';

// Placeholder screens for Main Menu, World Editor, and Store
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/landscape.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const GameScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              textStyle: const TextStyle(fontSize: 20),
            ),
            child: const Text('Enter World'),
          ),
        ),
      ),
    );
  }
}

class WorldEditorScreen extends StatelessWidget {
  const WorldEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('World Editor')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('World Editor (Placeholder)'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Game'),
            ),
          ],
        ),
      ),
    );
  }
}

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Store (Placeholder)'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Game'),
            ),
          ],
        ),
      ),
    );
  }
}

// Game screen containing the GameWidget
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int _currentGameIndex = 0;
  final List<FlameGame Function(VoidCallback)> _gameFactories = [
    (switchCallback) => SpaceShooterGame(onTripleTap: switchCallback),
    (switchCallback) => PokimernGameV1(onTripleTap: switchCallback),
    (switchCallback) => PokimernGameV2(onTripleTap: switchCallback),
  ];

  void _cycleGame() {
    setState(() {
      _currentGameIndex = (_currentGameIndex + 1) % _gameFactories.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<FlameGame>(
        game: _gameFactories[_currentGameIndex](_cycleGame),
        overlayBuilderMap: {
          'MenuButton': (context, FlameGame game) => Positioned(
                top: 40,
                right: 10,
                child: ElevatedButton(
                  onPressed: () {
                    game.overlays.add('Menu');
                    game.pauseEngine();
                  },
                  child: const Text('Menu'),
                ),
              ),
          'Menu': (context, FlameGame game) => Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.black.withOpacity(0.7),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('Menu');
                          game.resumeEngine();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MainMenuScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text('Main Menu'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('Menu');
                          game.resumeEngine();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WorldEditorScreen(),
                            ),
                          );
                        },
                        child: const Text('World Editor'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          game.overlays.remove('Menu');
                          game.resumeEngine();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const StoreScreen(),
                            ),
                          );
                        },
                        child: const Text('Store'),
                      ),
                    ],
                  ),
                ),
              ),
        },
        initialActiveOverlays: const ['MenuButton'],
      ),
    );
  }
}

// Wrapper widget to manage the app
void main() {
  runApp(const MyGameApp());
}

class MyGameApp extends StatelessWidget {
  const MyGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const MainMenuScreen(),
    );
  }
}

// First Iteration: SpaceShooterGame
class SpaceShooterGame extends FlameGame with PanDetector, TapCallbacks {
  late Player player;
  final VoidCallback onTripleTap;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  SpaceShooterGame({required this.onTripleTap});

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
    player.setVelocity(Vector2.zero());
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final delta = info.delta.global;
    const speed = 50.0;

    if (delta.x.abs() > delta.y.abs()) {
      if (delta.x < 0) {
        player.setVelocity(Vector2(-speed, 0));
      } else if (delta.x > 0) {
        player.setVelocity(Vector2(speed, 0));
      }
    } else {
      if (delta.y < 0) {
        player.setVelocity(Vector2(0, -speed));
      } else if (delta.y > 0) {
        player.setVelocity(Vector2(0, speed));
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    player.setVelocity(Vector2.zero());
  }

  @override
  void onTapDown(TapDownEvent event) {
    final now = DateTime.now();
    const tripleTapDuration = Duration(milliseconds: 500);

    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > tripleTapDuration) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    if (_tapCount == 3) {
      _tapCount = 0;
      _lastTapTime = null;
      pauseEngine();
      onTripleTap();
    }
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
    position += velocity * dt;
  }

  void setVelocity(Vector2 newVelocity) {
    velocity = newVelocity;
  }
}

// Second Iteration: PokimernGameV1
class PokimernGameV1 extends FlameGame with PanDetector, TapCallbacks {
  late PlayerV1 player;
  final VoidCallback onTripleTap;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  PokimernGameV1({required this.onTripleTap});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      await Flame.images.load('character_base_16x16.png');
    } catch (e) {
      print('Error loading spritesheet: $e');
    }

    player = PlayerV1(game: this)
      ..position = size / 2
      ..size = Vector2(48, 48)
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
    const speed = 100.0;

    if (delta.x.abs() > delta.y.abs()) {
      if (delta.x < 0) {
        player.setVelocity(Vector2(-speed, 0));
        player.current = PlayerState.left;
      } else if (delta.x > 0) {
        player.setVelocity(Vector2(speed, 0));
        player.current = PlayerState.right;
      }
    } else {
      if (delta.y < 0) {
        player.setVelocity(Vector2(0, -speed));
        player.current = PlayerState.backward;
      } else if (delta.y > 0) {
        player.setVelocity(Vector2(0, speed));
        player.current = PlayerState.forward;
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    player.setVelocity(Vector2.zero());
    player.current = PlayerState.idle;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final now = DateTime.now();
    const tripleTapDuration = Duration(milliseconds: 500);

    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > tripleTapDuration) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    if (_tapCount == 3) {
      _tapCount = 0;
      _lastTapTime = null;
      pauseEngine();
      onTripleTap();
    }
  }
}

enum PlayerState { forward, backward, right, left, idle }

class PlayerV1 extends SpriteAnimationGroupComponent<PlayerState> {
  Vector2 velocity = Vector2.zero();
  final FlameGame game;

  PlayerV1({required this.game}) : super(size: Vector2(16, 16));

  @override
  Future<void> onLoad() async {
    try {
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
    position.x = position.x.clamp(0.0, game.size.x - size.x);
    position.y = position.y.clamp(0.0, game.size.y - size.y);
  }

  void setVelocity(Vector2 newVelocity) {
    velocity = newVelocity;
  }
}

// Third Iteration: PokimernGameV2
class PokimernGameV2 extends FlameGame with PanDetector, TapCallbacks {
  late PlayerV2 player;
  late SpriteComponent map;
  final VoidCallback onTripleTap;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  PokimernGameV2({required this.onTripleTap});

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    try {
      await Flame.images.load('character_base_16x16.png');
    } catch (e) {
      print('Error loading player spritesheet: $e');
    }

    try {
      await Flame.images.load('tilesheet_basic.png');
    } catch (e) {
      print('Error loading map PNG: $e');
    }

    final mapSprite = await Sprite.load('tilesheet_basic.png');
    const mapWidth = 1280.0;
    const mapHeight = 1280.0;
    map = SpriteComponent(
      sprite: mapSprite,
      size: Vector2(mapWidth, mapHeight),
      anchor: Anchor.center,
    );
    map.position = Vector2(mapWidth / 2, mapHeight / 2);
    add(map);

    player = PlayerV2(game: this)
      ..position = size / 2
      ..size = Vector2(48, 48)
      ..anchor = Anchor.center;
    add(player);

    camera.setBounds(Rectangle.fromLTRB(0, 0, mapWidth, mapHeight));
  }

  @override
  void onPanStart(DragStartInfo info) {
    player.setVelocity(Vector2.zero());
    player.current = PlayerState.idle;
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    final delta = info.delta.global;
    const speed = 100.0;
    const deadzone = 0.5;

    if (delta.length < deadzone) {
      return;
    }

    if (delta.x.abs() > delta.y.abs()) {
      if (delta.x < 0) {
        player.setVelocity(Vector2(-speed, 0));
        player.current = PlayerState.left;
      } else if (delta.x > 0) {
        player.setVelocity(Vector2(speed, 0));
        player.current = PlayerState.right;
      }
    } else {
      if (delta.y < 0) {
        player.setVelocity(Vector2(0, -speed));
        player.current = PlayerState.backward;
      } else if (delta.y > 0) {
        player.setVelocity(Vector2(0, speed));
        player.current = PlayerState.forward;
      }
    }
  }

  @override
  void onPanEnd(DragEndInfo info) {
    player.setVelocity(Vector2.zero());
    player.current = PlayerState.idle;
  }

  @override
  void onTapDown(TapDownEvent event) {
    final now = DateTime.now();
    const tripleTapDuration = Duration(milliseconds: 500);

    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > tripleTapDuration) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    if (_tapCount == 3) {
      _tapCount = 0;
      _lastTapTime = null;
      pauseEngine();
      onTripleTap();
    }
  }
}

class PlayerV2 extends SpriteAnimationGroupComponent<PlayerState> {
  Vector2 velocity = Vector2.zero();
  final FlameGame game;

  PlayerV2({required this.game}) : super(size: Vector2(16, 16));

  @override
  Future<void> onLoad() async {
    try {
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
    position = game.size / 2;
    final map = (game as PokimernGameV2).map;
    map.position -= velocity * dt;

    const mapWidth = 1280.0;
    const mapHeight = 1280.0;
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