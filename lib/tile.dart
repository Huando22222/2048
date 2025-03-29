// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:two048/game_values.dart';

class Tile {
  final double x, y;
  int value;
  late Animation<double> size;
  late Animation<double> animatedX;
  late Animation<double> animatedY;
  late Animation<double> animatedValue;
  Tile({
    required this.x,
    required this.y,
    required this.value,
  }) {
    resetAnimations();
  }

  void appear({required Animation<double> parent}) {
    // size = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
    //     parent: parent, curve: Interval(GameValues.moveInterval, 1.0)));
  }

  void moveTo({
    required Animation<double> parent,
    required double toX,
    required double toY,
  }) {
    Animation<double> curved = CurvedAnimation(
        parent: parent,
        curve: Interval(0.0, 1
            // GameValues.moveInterval,
            ));
    animatedX = Tween<double>(
      begin: x,
      end: toX,
    ).animate(curved);
    animatedY = Tween<double>(
      begin: y,
      end: toY,
    ).animate(curved);
  }

  void resetAnimations() {
    animatedX = AlwaysStoppedAnimation(x.toDouble());
    animatedY = AlwaysStoppedAnimation(y.toDouble());
    size = AlwaysStoppedAnimation(1.0);
    animatedValue = AlwaysStoppedAnimation(value.toDouble());
  }
}

class TileWidget extends StatelessWidget {
  final double top;
  final double left;
  final double tileSize;
  final double containerSize;
  final int value;
  const TileWidget({
    super.key,
    required this.top,
    required this.left,
    required this.tileSize,
    required this.containerSize,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      width: tileSize,
      height: tileSize,
      child: Center(
        child: Container(
          height: containerSize,
          width: containerSize,
          decoration: BoxDecoration(
            color: GameValues.getTileColor(value),
            borderRadius: BorderRadius.circular(GameValues.tileRadius),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: GameValues.getTextStyle(value),
            ),
          ),
        ),
      ),
    );
  }
}
