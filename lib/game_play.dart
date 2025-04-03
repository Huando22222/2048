import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late AnimationController _controller;
  late AnimationController _appearController;
  late AnimationController _gradientController;
  late AnimationController _offsetController;
  late AnimationController _popupController;
  late Animation<double> _animatedSizeScore;
  late Animation<double> _shakeAnimation;
  late Animation<Offset> _offsetAnimation;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;
  late Animation<Color?> _color3;
  bool _ableToSwipe = true;
  bool _isFinish = false;
  int _score = 0;
  int _bestScore = 0;
  int _moved = 0;
  final List<List<Tile>> _tiles = List.generate(
      4,
      (y) => List.generate(
          4, (x) => Tile(x: x.toDouble(), y: y.toDouble(), value: 0)));

  Iterable<List<Tile>> get _cols => // 1
      List.generate(4, (x) => List.generate(4, (y) => _tiles[y][x]));

  Iterable<Tile> get _flattenedTiles => _tiles.expand((element) => element);
  @override
  void initState() {
    super.initState();
    // getBestScore();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: GameValues.millisecondsAnimation),
    );
    _appearController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: GameValues.millisecondsAnimation,
      ),
    );
    _offsetController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: GameValues.millisecondsAnimation,
      ),
    );
    _offsetAnimation =
        Tween(begin: Offset(0, -3), end: Offset(0, 0)).animate(CurvedAnimation(
      parent: _offsetController,
      curve: Curves.bounceOut,
    ));
    _animatedSizeScore = Tween(begin: 1.20, end: 1.0).animate(CurvedAnimation(
        parent: _controller,
        curve: Interval(
          GameValues.moveInterval,
          1,
          curve: Curves.bounceOut,
        )));
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 5.0), weight: .2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: .2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: .2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: -5.0), weight: .2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 0.0), weight: .2),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          GameValues.moveInterval,
          1,
        ),
      ),
    );
    _appearController.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          for (var tile in _flattenedTiles) {
            tile.stopAnimatedSize();
          }

          if (_isFinish) {
            _offsetController.forward();
          }
        }
      },
    );
    _controller.addStatusListener(
      (status) {
        if (status == AnimationStatus.completed) {
          _appearController.forward(from: 0.0);
          for (var tile in _flattenedTiles) {
            tile.resetAnimations();
          }
          _ableToSwipe = true;
        }
      },
    );
    _gradientController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _color1 = ColorTween(
      begin: Colors.amber,
      end: Colors.blue,
    ).animate(_gradientController);

    _color2 = ColorTween(
      begin: Colors.orange,
      end: Colors.purple,
    ).animate(_gradientController);

    _color3 = ColorTween(
      begin: Colors.red,
      end: Colors.green,
    ).animate(_gradientController);
    newGame();
  }

  newGame() async {
    await getBestScore();
    setState(() {
      for (var element in _flattenedTiles) {
        element.value = 0;
        element.resetAnimations();
      }
      _isFinish = false;
      addNewTile();
      _score = 0;
      _moved = 0;
      _controller.forward(from: 0.0);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _appearController.dispose();
    _controller.dispose();
    _gradientController.dispose();
    _popupController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = 16.0;
    //
    final gridSize = size.width - padding * 2;
    final tileSize = (gridSize - GameValues.gridPadding * 2) / 4;

    final List<Widget> stackItems = [];
    stackItems.addAll(_flattenedTiles.map(
      (e) => Positioned(
        top: e.y.toDouble() * tileSize,
        left: e.x.toDouble() * tileSize,
        width: tileSize,
        height: tileSize,
        child: Center(
          child: Container(
            height: tileSize - GameValues.gridPadding * 2,
            width: tileSize - GameValues.gridPadding * 2,
            decoration: BoxDecoration(
              color: GameValues.emptyTileColor,
              borderRadius: BorderRadius.circular(GameValues.tileRadius),
            ),
          ),
        ),
      ),
    ));
    stackItems.addAll(_flattenedTiles.map(
      (e) {
        return AnimatedBuilder(
          animation: Listenable.merge([_controller, _appearController]),
          // animation: controller,
          builder: (context, child) {
            if (e.animatedValue.value == 0) {
              return SizedBox.shrink();
            } else {
              return TileWidget(
                left: e.animatedX.value * tileSize,
                top: e.animatedY.value * tileSize,
                tileSize: tileSize,
                containerSize: (tileSize - GameValues.gridPadding * 2) *
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
      body: Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy > 250) {
                merge(direction: SwipeDirection.down);
              } else if (details.velocity.pixelsPerSecond.dy < -250) {
                merge(direction: SwipeDirection.up);
              }
            },
            onHorizontalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dx > 1000) {
                merge(direction: SwipeDirection.right);
              } else if (details.velocity.pixelsPerSecond.dx < -1000) {
                merge(direction: SwipeDirection.left);
              }
            },
            child: SizedBox(
              height: size.height,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).padding.top + 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "2048",
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF776E65),
                          ),
                        ),
                        Spacer(),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            Row(
                              spacing: 10,
                              children: [
                                AnimatedBuilder(
                                  animation: Listenable.merge(
                                      [_gradientController, _shakeAnimation]),
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(_shakeAnimation.value, 0),
                                      child: Transform.scale(
                                        scale: _animatedSizeScore.value,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey,
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            gradient: LinearGradient(
                                              colors: [
                                                _color1.value ?? Colors.amber,
                                                _color2.value ?? Colors.orange,
                                                _color3.value ?? Colors.red,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    Colors.black.withAlpha(50),
                                                blurRadius: 4,
                                                offset: Offset(2, 2),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(2),
                                          child: _buildScore(
                                              content: "Score",
                                              score: "$_score"),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _buildScore(
                                    content: "Best", score: "$_bestScore"),
                              ],
                            ),
                            Row(
                              spacing: 10,
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    newGame();
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: Color(0xffeccd71),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Icon(
                                      Icons.replay_sharp,
                                      color: Color(0xffF9F6F2),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                  Spacer(
                    flex: 1,
                  ),
                  Container(
                    height: gridSize,
                    width: gridSize,
                    padding: EdgeInsets.all(GameValues.gridPadding),
                    decoration: BoxDecoration(
                      color: GameValues.tileBorderColor,
                      borderRadius:
                          BorderRadius.circular(GameValues.borderRadius),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ...stackItems,
                      ],
                    ),
                  ),
                  Spacer(
                    flex: 4,
                  ),
                ],
              ),
            ),
          ),
          if (_isFinish) ...[
            Positioned.fill(
              child: Container(
                color: Colors.white.withAlpha(150),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: Container(
                    height: 300,
                    decoration: BoxDecoration(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Game Over!",
                          style: TextStyle(
                            fontSize: 50,
                            color: Color(0xFF776E65),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: "You earned ",
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFF776E65),
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text: _score.toString(),
                                style: TextStyle(
                                  fontSize: 30,
                                  color: Color(0xFFf59839),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(text: " points\nwith "),
                              TextSpan(text: _moved.toString()),
                              TextSpan(text: " moves "),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        GestureDetector(
                          onTap: () {
                            newGame();
                          },
                          child: Container(
                            decoration: BoxDecoration(),
                            child: Text(
                              'Try again',
                              style: TextStyle(
                                fontSize: 30,
                                color: Color(0xFF776E65),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void addNewTile() {
    List<Tile> emptyTiles = _flattenedTiles.where(
      (element) {
        return element.value == 0;
      },
    ).toList();

    emptyTiles.shuffle();
    int canAddMore = emptyTiles.length >= 2 ? 2 : 1;
    // List<int> newValueTile = _score > 50 ? [2, 4] : [2];
    List<int> newValueTile = [2, 4, 8];
    int canRandom = _score < 50
        ? 1
        : _score < 3000
            ? 2
            : 3;
    for (int i = 0; i < canAddMore; i++) {
      int newValue = newValueTile[Random().nextInt(canRandom)];
      _tiles[emptyTiles[i].y.toInt()][emptyTiles[i].x.toInt()].value = newValue;
      _tiles[emptyTiles[i].y.toInt()][emptyTiles[i].x.toInt()]
          .appear(parent: _appearController);
      // _score += newValue;
      // .appear(parent: controller);
      // log('new tile position [${emptyTiles[i].x.toInt()},${emptyTiles[i].y.toInt()}]');
    }

    // check game finished
    if (emptyTiles.length <= 2) {
      bool blockRows = _tiles.every((row) => checkGameOver(row));
      bool blockCols = _cols.every((row) => checkGameOver(row));

      if (blockRows && blockCols) {
        if (_score > _bestScore) {
          setBestScore(bestScore: _score);
        }
        _isFinish = true;
      }
      return;
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
      _moved++;
      setState(() {
        addNewTile();
        _controller.forward(from: 0.0);
        _ableToSwipe = false;
      });
    }
  }

  bool mergeLeft() => _tiles.map((e) => mergeTiles(e)).toList().any((e) => e);

  bool mergeRight() =>
      _tiles.map((e) => mergeTiles(e.reversed.toList())).toList().any((e) => e);

  bool mergeUp() => _cols.map((e) => mergeTiles(e)).toList().any((e) => e);

  bool mergeDown() =>
      _cols.map((e) => mergeTiles(e.reversed.toList())).toList().any((e) => e);

  bool mergeTiles(List<Tile> tiles) {
    // String tmp = tiles.map((tile) => tile.value).join(', ');
    // log("each Row, col: $tmp");
    bool didChange = false;
    if (!_ableToSwipe) return didChange;

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
          tiles[j]
              .moveTo(parent: _controller, toX: tiles[i].x, toY: tiles[i].y);
          if (mergeTile != null) {
            resultValue += mergeTile.value;
            mergeTile.moveTo(
              parent: _controller,
              toX: tiles[i].x,
              toY: tiles[i].y,
            );

            mergeTile.bounce(_controller);
            mergeTile.changeNumber(_controller, resultValue.toDouble());
            mergeTile.value = 0;
            tiles[j].changeNumber(_controller, 0);
            _score += resultValue;
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

  bool checkGameOver(List<Tile> tiles) {
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i].value == tiles[i + 1].value) return false;
    }
    return true;
  }

  Future<void> getBestScore() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    final result = pref.getInt("best_score");
    if (result == null) {
      setBestScore(bestScore: 0);
      _bestScore = 0;
    } else {
      _bestScore = result;
    }
  }

  void setBestScore({required int bestScore}) async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setInt("best_score", bestScore);
  }

  Widget _buildScore({
    required String content,
    required String score,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xffa49381),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 5,
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: "$content\n",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xffeee4da),
          ),
          children: [
            TextSpan(
              text: score,
              style: GameValues.getScoreTextStyle(_score.toInt()).copyWith(
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
    );
  }
}
