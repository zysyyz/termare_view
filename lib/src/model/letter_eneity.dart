import 'package:flutter/material.dart';
import 'package:termare_view/src/painter/model/position.dart';

class LetterEntity {
  LetterEntity({
    this.doubleWidth = false,
    this.backgroundColor = Colors.transparent,
    @required this.content,
    @required this.letterWidth,
    @required this.letterHeight,
    @required this.position,
    @required this.textStyle,
  });
  final String content;
  final double letterWidth;
  final double letterHeight;
  final Position position;
  final TextStyle textStyle;
  final Color backgroundColor;
  final bool doubleWidth;
}
