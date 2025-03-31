import 'dart:developer';
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:two048/game_values.dart';
import 'package:two048/tile.dart';

enum SwipeDirection {
  up,
  down,
  left,
  right,
}

class GamePlay extends StatefulWidget {
  const GamePlay({super.key});

  @override
  State<GamePlay> createState() => _GamePlayState();
}

class _GamePlayState extends State<GamePlay> with TickerProviderStateMixin {
  // with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late AnimationController appearController;
  late Animation<double> animatedSizeScore;
  late Animation<double> shakeAnimation;
  bool ableToSwipe = true;
  int score = 0;

  List<List<Tile>> tiles = List.generate(
      4,
      (y) => List.generate(
          4, (x) => Tile(x: x.toDouble(), y: y.toDouble(), value: 0)));

  Iterable<List<Tile>> get cols => // 1
      List.generate(4, (x) => List.generate(4, (y) => tiles[y][x]));
  // List<Tile> toAdd = [];

  Iterable<Tile> get flattenedTiles => tiles.expand((element) => element);
  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: GameValues.millisecondsAnimation),
    );
    appearController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: GameValues.millisecondsAnimation,
        // milliseconds: (GameValues.millisecondsAnimation / 2).round(),
      ),
    );
    animatedSizeScore = Tween(begin: 1.20, end: 1.0).animate(CurvedAnimation(
        parent: controller,
        curve: Interval(
          GameValues.moveInterval,
          1,
          curve: Curves.bounceOut,
        )));
    shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0), weight: .2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: .2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: .2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: .2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: .2),
    ]).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          GameValues.moveInterval,
          1,
        ),
      ),
    );
    appearController.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          log("appearController completed");
          for (var tile in flattenedTiles) {
            tile.stopAnimatedSize();
          }
        }
      },
    );
    controller.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          log("controller completed");
          appearController.forward(from: 0.0);
          for (var tile in flattenedTiles) {
            tile.resetAnimations();
          }
          ableToSwipe = true;
        }
      },
    );
    newGame();
  }

  void newGame() {
    setState(() {
      for (var element in flattenedTiles) {
        element.value = 0;
        element.resetAnimations();
      }
      addNewTile();
      score = 0;
      controller.forward(from: 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = 16.0;
    //
    final gridSize = size.width - padding * 2;
    final tileSize = (gridSize - GameValues.tilePadding * 2) / 4;

    final List<Widget> stackItems = [];
    stackItems.addAll(flattenedTiles.map(
      (e) => Positioned(
        top: e.y.toDouble() * tileSize,
        left: e.x.toDouble() * tileSize,
        width: tileSize,
        height: tileSize,
        child: Center(
          child: Container(
            height: tileSize - GameValues.tilePadding * 2,
            width: tileSize - GameValues.tilePadding * 2,
            decoration: BoxDecoration(
              color: GameValues.emptyTileColor,
              borderRadius: BorderRadius.circular(GameValues.tileRadius),
            ),
          ),
        ),
      ),
    ));
    stackItems.addAll(flattenedTiles.map(
      (e) {
        return AnimatedBuilder(
          animation: Listenable.merge([controller, appearController]),
          // animation: controller,
          builder: (context, child) {
            if (e.animatedValue.value == 0) {
              return SizedBox.shrink();
            } else {
              return TileWidget(
                left: e.animatedX.value * tileSize,
                top: e.animatedY.value * tileSize,
                tileSize: tileSize,
                containerSize: (tileSize - GameValues.tilePadding * 2) *
                    e.animatedSize.value,
                value: e.animatedValue.value.toInt(),
              );
            }
          },
        );
      },
    ));

    return Scaffold(
      backgroundColor: GameValues.boardBackgroundColor,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy > 20) {
            merge(direction: SwipeDirection.down);
          } else if (details.velocity.pixelsPerSecond.dy < -20) {
            merge(direction: SwipeDirection.up);
          }
        },
        onHorizontalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dx > 20) {
            merge(direction: SwipeDirection.right);
          } else if (details.velocity.pixelsPerSecond.dx < -20) {
            merge(direction: SwipeDirection.left);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            SizedBox(
              height: size.height * 0.2,
              width: double.infinity,
              child: Center(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(shakeAnimation.value, 0),
                      child: Transform.scale(
                        scale: animatedSizeScore.value,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber,
                                Colors.orange,
                                Colors.red,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 12),
                                Text(
                                  "Score: $score",
                                  style: GameValues.getScoreTextStyle(
                                          score.toInt())
                                      .copyWith(
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withAlpha(100),
                                        offset: Offset(2, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Center(
              child: Container(
                height: gridSize,
                width: gridSize,
                padding: EdgeInsets.all(GameValues.tilePadding),
                decoration: BoxDecoration(
                  color: GameValues.tileBorderColor,
                  borderRadius: BorderRadius.circular(GameValues.borderRadius),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ...stackItems,
                  ],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                newGame();
              },
              child: Text("new game"),
            ),
            ElevatedButton(
              onPressed: () {
                merge(direction: SwipeDirection.up);
              },
              child: Text("up"),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    merge(direction: SwipeDirection.left);
                  },
                  child: Text("left"),
                ),
                ElevatedButton(
                  onPressed: () {
                    merge(direction: SwipeDirection.right);
                  },
                  child: Text("right"),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                merge(direction: SwipeDirection.down);
              },
              child: Text("down"),
            ),
          ],
        ),
      ),
    );
  }

  void addNewTile() {
    List<Tile> emptyTiles = flattenedTiles.where(
      (element) {
        return element.value == 0;
      },
    ).toList();

    if (emptyTiles.isEmpty) return;

    emptyTiles.shuffle();
    int canAddMore = emptyTiles.length >= 2 ? 2 : 1;
    List<int> newValueTile = score > 50 ? [2, 4] : [2];
    // log("addNewTile================================$canAddMore");
    for (int i = 0; i < canAddMore; i++) {
      int newValue = newValueTile[Random().nextInt(newValueTile.length)];
      tiles[emptyTiles[i].y.toInt()][emptyTiles[i].x.toInt()].value = newValue;
      tiles[emptyTiles[i].y.toInt()][emptyTiles[i].x.toInt()]
          .appear(parent: appearController);

      score += newValue;
      // .appear(parent: controller);
      // log('new tile position [${emptyTiles[i].x.toInt()},${emptyTiles[i].y.toInt()}]');
    }
  }

  void merge({required SwipeDirection direction}) {
    bool didMerge = false;
    switch (direction) {
      case SwipeDirection.up:
        didMerge = mergeUp();
        break;
      case SwipeDirection.down:
        didMerge = mergeDown();
        break;
      case SwipeDirection.left:
        didMerge = mergeLeft();
        break;
      case SwipeDirection.right:
        didMerge = mergeRight();
        break;
    }
    if (didMerge) {
      setState(() {
        addNewTile();
        controller.forward(from: 0.0);
        ableToSwipe = false;
      });
    }
  }

  bool mergeLeft() => tiles.map((e) => mergeTiles(e)).toList().any((e) => e);

  bool mergeRight() =>
      tiles.map((e) => mergeTiles(e.reversed.toList())).toList().any((e) => e);

  bool mergeUp() => cols.map((e) => mergeTiles(e)).toList().any((e) => e);

  bool mergeDown() =>
      cols.map((e) => mergeTiles(e.reversed.toList())).toList().any((e) => e);

  bool mergeTiles(List<Tile> tiles) {
    // String tmp = tiles.map((tile) => tile.value).join(', ');
    // log("each Row, col: $tmp");
    bool didChange = false;
    if (!ableToSwipe) return didChange;

    for (int i = 0; i < tiles.length; i++) {
      for (int j = i; j < tiles.length; j++) {
        if (tiles[j].value == 0) continue;

        Tile? mergeTile;

        for (var element in tiles.skip(j + 1)) {
          if (element.value != 0) {
            mergeTile = element;
            break;
          }
        } // 0 8 0 8
        // 0 0 8 2
        if (mergeTile != null && mergeTile.value != tiles[j].value) {
          mergeTile = null;
        }
        if (i != j || mergeTile != null) {
          didChange = true;
          int resultValue = tiles[j].value;
          tiles[j].moveTo(parent: controller, toX: tiles[i].x, toY: tiles[i].y);
          if (mergeTile != null) {
            resultValue += mergeTile.value;
            mergeTile.moveTo(
              parent: controller,
              toX: tiles[i].x,
              toY: tiles[i].y,
            );

            // mergeTile.bounce(controller);
            mergeTile.changeNumber(controller, resultValue.toDouble());
            mergeTile.value = 0;
            tiles[j].changeNumber(controller, 0);
          }
          tiles[j].value = 0;
          tiles[i].value = resultValue;
          // String tmp2 = tiles
          //     .map((tile) =>
          //         "[${tile.x.toInt()},${tile.y.toInt()}]${tile.value}")
          //     .join(', ');
          // log("- $tmp2\n");
        }
        break;
      }
    }
    return didChange;
  }
}
