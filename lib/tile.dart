// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:two048/game_values.dart';

class Tile {
  final double x, y;
  int value;
  late Animation<double> animatedSize;
  late Animation<double> animatedX;
  late Animation<double> animatedY;
  late Animation<double> animatedValue;
  Tile({
    required this.x,
    required this.y,
    required this.value,
  }) {
    resetAnimations();
    stopAnimatedSize();
  }

  void appear({required Animation<double> parent}) {
    animatedSize = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
        parent: parent,
        curve: Interval(
          0,
          1.0,
        )));
    // parent: parent, curve: Interval(GameValues.moveInterval, 1.0)));
  }

  void stopAnimatedSize() {
    animatedSize = AlwaysStoppedAnimation(1.0);
  }

  void moveTo({
    required Animation<double> parent,
    required double toX,
    required double toY,
  }) {
    Animation<double> curved = CurvedAnimation(
        parent: parent,
        curve: Interval(
          0.0,
          GameValues.moveInterval,
        ));

    // log('moveTo [${toX.toInt()},${toY.toInt()}] <- [${x.toInt()},${y.toInt()}] current: [${animatedX.value.toInt()},${animatedY.value.toInt()}] value: $value');
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
    animatedValue = AlwaysStoppedAnimation(value.toDouble());
    // animatedSize = AlwaysStoppedAnimation(1.0);
    animatedX = AlwaysStoppedAnimation(x.toDouble());
    animatedY = AlwaysStoppedAnimation(y.toDouble());
  }

  void bounce(Animation<double> parent) {
    animatedSize = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1.0),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1.0),
    ]).animate(CurvedAnimation(
        parent: parent, curve: Interval(GameValues.moveInterval, 1.0)));
  }

  void changeNumber(Animation<double> parent, double newValue) {
    animatedValue = TweenSequence([
      // TweenSequenceItem(tween: ConstantTween(value.toDouble()), weight: .5),
      // TweenSequenceItem(tween: ConstantTween(newValue), weight: .5),
      TweenSequenceItem(tween: ConstantTween(value.toDouble()), weight: .01),
      TweenSequenceItem(tween: ConstantTween(newValue), weight: .99),
    ]).animate(CurvedAnimation(
        parent: parent, curve: Interval(GameValues.moveInterval, 1.0)));
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
