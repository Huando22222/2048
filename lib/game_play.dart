import 'dart:developer';

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

class _GamePlayState extends State<GamePlay>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
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
      duration: Duration(milliseconds: 500),
    );
    controller.addStatusListener(
      (status) {
        if (status.isCompleted) {
          // if (status == AnimationStatus.completed) {
          for (var tile in flattenedTiles) {
            tile.resetAnimations();
          }
          score = 0;
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
          animation: controller,
          builder: (context, child) {
            if (e.value == 0) {
              return SizedBox.shrink();
            } else {
              return TileWidget(
                left: e.animatedX.value * tileSize,
                top: e.animatedY.value * tileSize,
                tileSize: tileSize,
                containerSize:
                    (tileSize - GameValues.tilePadding * 2) * e.size.value,
                value: e.value,
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
            Container(
              child: Text(score.toString()),
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
                  child: Text("right"),
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
            ElevatedButton(
              onPressed: () {
                addNewTile();
              },
              child: Text("new tile"),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // setState(() {});
                    controller.forward(from: 0.0);
                  },
                  child: Text("forward"),
                ),
                ElevatedButton(
                  onPressed: () {
                    for (var element in tiles) {
                      String tmp = element.map((tile) {
                        return "[${tile.x.toInt()},${tile.y.toInt()}]${tile.value}";
                      }).join(', ');
                      log(tmp);
                    }
                  },
                  child: Text("tiles value"),
                ),
                ElevatedButton(
                  onPressed: () {
                    log("[${tiles[3][1].x.toInt().toString()},${tiles[3][1].y.toInt().toString()}] ${tiles[3][1].value.toString()}");
                  },
                  child: Text("tile value"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void addNewTile() {
    // for (var element in flattenedTiles) {
    //   score += element.value;
    // }
    for (var element in tiles) {
      String tmp = element.map((tile) {
        return "[${tile.x.toInt()},${tile.y.toInt()}]${tile.value}";
      }).join(', ');
      log(tmp);
    }
    List<Tile> emptyTiles = flattenedTiles.where(
      (element) {
        return element.value == 0;
      },
    ).toList();

    if (emptyTiles.isEmpty) return;

    emptyTiles.shuffle();
    int canAddMore = emptyTiles.length >= 2 ? 2 : 1;
    log("addNewTile================================$canAddMore");
    for (int i = 0; i < canAddMore; i++) {
      // tiles[emptyTiles[i].x.toInt()][emptyTiles[i].y.toInt()].value = 2;
      // tiles[emptyTiles[i].x.toInt()][emptyTiles[i].y.toInt()]
      //     .appear(parent: controller);
      tiles[emptyTiles[i].y.toInt()][emptyTiles[i].x.toInt()].value = 2;
      tiles[emptyTiles[i].y.toInt()][emptyTiles[i].x.toInt()]
          .appear(parent: controller);
      log('new tile position [${emptyTiles[i].x.toInt()},${emptyTiles[i].y.toInt()}]');
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
    String tmp = tiles.map((tile) => tile.value).join(', ');
    log("each Row, col: $tmp");
    bool didChange = false;
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
          tiles[j].moveTo(
            parent: controller,
            toX: tiles[i].x,
            toY: tiles[i].y,
          );
          if (mergeTile != null) {
            resultValue += mergeTile.value;
            mergeTile.moveTo(
              parent: controller,
              toX: tiles[i].x,
              toY: tiles[i].y,
            );
            // log("[${mergeTile.x.toInt()},${mergeTile.y.toInt()}]${mergeTile.value}");
            // mergeTile.bounce(controller);
            // mergeTile.changeNumber(controller, resultValue);
            mergeTile.value = 0;
            // tiles[j].changeNumber(controller, 0);
          }
          tiles[j].value = 0;
          tiles[i].value = resultValue;
          String tmp2 = tiles
              .map((tile) =>
                  "[${tile.x.toInt()},${tile.y.toInt()}]${tile.value}")
              .join(', ');
          log("- $tmp2\n");
        }
        break;
      }
    }
    return didChange;
  }
}
