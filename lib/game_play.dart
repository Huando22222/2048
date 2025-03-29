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
  List<List<Tile>> tiles = List.generate(
      4,
      (y) => List.generate(
          4, (x) => Tile(x: x.toDouble(), y: y.toDouble(), value: 0)));

  Iterable<List<Tile>> get cols =>
      List.generate(4, (x) => List.generate(4, (y) => tiles[y][x]));
  // List<Tile> toAdd = [];
  Iterable<Tile> get flattenedTiles => tiles.expand((element) => element);

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    controller.addStatusListener(
      (status) {
        if (status.isCompleted) {
          for (var tile in flattenedTiles) {
            tile.resetAnimations();
          }
        }
      },
    );
    addNewTile();
    controller.forward();
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
                addNewTile();
                controller.forward(from: 0);
                // for (var element in cols) {
                //   log("[${element[1].x.toString()}][${element[1].y.toString()}] ${element[1].value.toString()}");
                // }
                // setState(() {});
                // merge(direction: SwipeDirection.up);
              },
              child: Text("setState"),
            ),
            ElevatedButton(
              onPressed: () {
                merge(direction: SwipeDirection.up);
                addNewTile();
                controller.forward(from: 0);
              },
              child: Text("right"),
            ),
            ElevatedButton(
              onPressed: () {
                // addNewTile();
                for (var i = 0; i < 4; i++) {
                  log("[${tiles[i][0].value.toString()}][${tiles[i][1].value.toString()}][${tiles[i][2].value.toString()}][${tiles[i][3].value.toString()}]");
                  log(" ");
                }
                setState(() {});
// [log] [0][0][0][0]
// [log] [2][0][0][0]
// [log] [0][0][2][0]
// [log] [0][0][0][0]
                // setState(() {});
              },
              child: Text("log"),
            ),
          ],
        ),
      ),
    );
  }

  void addNewTile() {
    List<Tile> empty = flattenedTiles.where(
      (element) {
        return element.value == 0;
      },
    ).toList();

    if (empty.isEmpty) return;

    empty.shuffle();
    int canAddMore = empty.length >= 2 ? 2 : 1;

    empty.shuffle();

    for (int i = 0; i < canAddMore; i++) {
      tiles[empty[i].x.toInt()][empty[i].y.toInt()].value = 2;
      tiles[empty[i].x.toInt()][empty[i].y.toInt()].appear(parent: controller);
    }
  }

  void merge({required SwipeDirection direction}) {
    log("direction: ${direction.name}");
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
      });
      controller.forward(from: 0.0);
    }
  }

  bool mergeLeft() => tiles.map((e) => mergeTiles(e)).toList().any((e) => e);

  bool mergeRight() =>
      tiles.map((e) => mergeTiles(e.reversed.toList())).toList().any((e) => e);

  bool mergeUp() => cols.map((e) => mergeTiles(e)).toList().any((e) => e);

  bool mergeDown() =>
      cols.map((e) => mergeTiles(e.reversed.toList())).toList().any((e) => e);

  bool mergeTiles(List<Tile> tiles) {
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
        } // 0 0 8 8
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
                parent: controller, toX: tiles[i].x, toY: tiles[i].y);
            // mergeTile.bounce(controller);
            // mergeTile.changeNumber(controller, resultValue);
            mergeTile.value = 0;
            // tiles[j].changeNumber(controller, 0);
          }
          tiles[j].value = 0;
          tiles[i].value = resultValue;
        }
        break;
      }
    }
    return didChange;
  }
}
