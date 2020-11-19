import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:global_repository/global_repository.dart';
import 'package:termare/src/config/cache.dart';
import 'package:termare/src/painter/model/position.dart';
import 'package:termare/src/termare_controller.dart';
import 'package:termare/src/theme/term_theme.dart';

const double letterWidth = 5.0;
const double letterHeight = 12.0;

// int rowLength = 80;
// int columnLength = 24;
TextLayoutCache cache = TextLayoutCache(TextDirection.ltr, 4068);

class TermarePainter extends CustomPainter {
  TermarePainter({
    this.controller,
    this.theme,
    this.rowLength,
    this.columnLength,
    this.defaultOffsetY,
    this.color = Colors.white,
    this.input,
    this.lastLetterPositionCall,
  }) {
    termWidth = columnLength * letterWidth;
    termHeight = rowLength * letterHeight;
  }
  final TermareController controller;
  final int rowLength;
  final int columnLength;
  double termWidth;
  double termHeight;
  int curPaintIndex = 0;
  final TermTheme theme;
  List<Color> colors = [
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.brown,
    Colors.cyan,
  ];
  final Color color;
  final double defaultOffsetY;
  final void Function(double lastLetterPosition) lastLetterPositionCall;
  double padding;
  final String input;
  Function eq = const ListEquality().equals;
  Position _position = Position(0, 0);
  bool showCursor = true;

  TextStyle defaultStyle = TextStyle(
    textBaseline: TextBaseline.ideographic,
    height: 1,
    fontSize: 8.0,
    color: Colors.white,
    fontWeight: FontWeight.w500,
    // backgroundColor: Colors.black,
    fontFamily: 'monospace',
  );
  void drawLine(Canvas canvas) async {
    Paint paint = Paint();
    paint.strokeWidth = 1;
    paint.color = Colors.grey.withOpacity(0.4);
    for (int j = 0; j <= rowLength; j++) {
      // print(j);
      canvas.drawLine(
        Offset(0, j * letterHeight),
        Offset(
          termWidth,
          j * letterHeight,
        ),
        paint,
      );
    }
    for (int k = 0; k <= columnLength; k++) {
      canvas.drawLine(
        Offset(
          k * letterWidth,
          0,
        ),
        Offset(k * letterWidth, termHeight),
        paint,
      );
    }
  }

  void drawBackground(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, termWidth, termHeight),
      Paint()..color = Colors.black,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    PrintUtil.printd(
      '${'>' * 32} $this defaultOffsetY->$defaultOffsetY',
      32,
    );
    int outLine = defaultOffsetY.toInt() ~/ letterHeight.toInt();
    PrintUtil.printd(
      '$this defaultOffsetY->$defaultOffsetY  outLine->$outLine  defaultOffsetY.toInt()->${defaultOffsetY.toInt()}',
      31,
    );
    _position = Position(0, 0);
    curPaintIndex = 0;
    drawBackground(canvas);
    // print('_position->$_position');
    final List<String> outList = input.split('\n');
    PrintUtil.printd(
      '${'>' * 32} input  ',
      32,
    );
    print(input);
    PrintUtil.printd(
      '${'<' * 32} ',
      32,
    );
    TextStyle curStyle = defaultStyle;
    for (int j = -outLine; j < outList.length; j++) {
      String line = outList[j];
      if (line.contains('|')) {
        print('wait');
        for (int char in line.codeUnits) {
          PrintUtil.printd('char->$char', 34);
        }
      }
      PrintUtil.printd('line->$line', 35);
      PrintUtil.printd('line.codeUnits->${line.codeUnits}', 35);
      // continue;s
      for (int i = 0; i < line.length; i++) {
        // print(line[i]);
        // print(line[i].codeUnits);
        /// ------------------ c0 ----------------------
        if (eq(line[i].codeUnits, [0x07])) {
          PrintUtil.printn('<- C0 Bell ->', 31, 47);
          continue;
        }
        if (eq(line[i].codeUnits, [0x08])) {
          // 光标左移动
          PrintUtil.printn('<- C0 Backspace ->', 31, 47);
          final RegExp doubleByteReg = RegExp('[^\x00-\xff]');
          bool isDoubleByte = doubleByteReg.hasMatch(line[i - 1]);
          if (isDoubleByte) {
            // print('双字节字符---->${line[i]}');
            moveToNextOffset(-1);
          }
          moveToNextOffset(-1);
          continue;
        }

        if (eq(line[i].codeUnits, [0x09])) {
          moveToNextOffset(4);

          PrintUtil.printn('<- C0 Horizontal Tabulation ->', 31, 47);
          // print('<- Horizontal Tabulation ->');
          continue;
        }
        if (eq(line[i].codeUnits, [0x0a]) ||
            eq(line[i].codeUnits, [0x0b]) ||
            eq(line[i].codeUnits, [0x0c])) {
          moveNewLineOffset();
          PrintUtil.printn('<- C0 Line Feed ->', 31, 47);
          continue;
        }
        if (eq(line[i].codeUnits, [0x0d])) {
          // ascii 13
          moveToLineFirstOffset();
          PrintUtil.printn('<- C0 Carriage Return ->', 31, 47);
          continue;
        }

        /// ------------------ c0 ----------------------
        ///
        if (eq(line[i].codeUnits, [0x1b])) {
          // print('<- ESC ->');
          i += 1;
          String curStr = line[i];
          PrintUtil.printd('preStr-> ESC curStr->$curStr', 31);
          switch (curStr) {
            case '[':
              i += 1;
              String curStr = line[i];
              PrintUtil.printd(
                'preStr-> \x1b[32m[\x1b[31m ->curStr-> \x1b[32m$curStr\x1b[31m',
                31,
              );
              switch (curStr) {
                // 27 91 75
                case 'K':
                  // i += 1;
                  // print(line[i - 5]);
                  final RegExp doubleByteReg = RegExp('[^\x00-\xff]');

                  // TODO 这个是删除的序列，写得有问题
                  // bool isDoubleByte = doubleByteReg.hasMatch(line[i - 5]);
                  // if (isDoubleByte) {
                  //   // print('数按字节字符---->${line[i]}');
                  // }
                  canvas.drawRect(
                    Rect.fromLTWH(
                      _position.dx * letterWidth,
                      _position.dy * letterHeight + defaultOffsetY,
                      false ? 2 * letterWidth : letterWidth,
                      letterHeight,
                    ),
                    Paint()..color = Colors.black,
                  );
                  continue;
                  break;
                case '?':
                  i += 1;
                  RegExp regExp = RegExp('l');
                  int w = line.substring(i).indexOf(regExp);
                  String number = line.substring(i, i + w);
                  if (number == '25') {
                    i += 2;
                    showCursor = false;
                  }
                  i += 1;
                  PrintUtil.printd('[ ? 后的值->${line.substring(i)}', 31);
                  continue;
                  break;
                default:
              }
              // print(line.substring(i + 2));
              final int charMindex = line.substring(i + 1).indexOf('m');

              // print('charMindex=======>$charMindex');
              String header = '';
              header = line.substring(i + 2, i + 1 + charMindex);
              for (var str in header.split(';')) {
                curStyle = getTextStyle(str, curStyle);
                // switch (str) {
                //   case '1':
                //     break;
                //   default:
                // }
              }
              i += header.length + 1;
              // print('header->$header');
              // for (int j = i + 2; j < line.length; j++) {
              //   print(line[j]);
              // }
              i++;
              break;
            default:
          }

          continue;
        }

        // print(line[i] == utf8.decode(TermControlSequences.buzzing));
        // canvas.drawRect(
        //   Rect.fromLTWH(curOffset * width.toDouble(), 0.0, 16, 16),
        //   Paint()..color = Colors.white,
        // );
        if (isOutTerm()) {
          continue;
        }

        final RegExp doubleByteReg = RegExp('[^\x00-\xff]');
        bool isDoubleByte = doubleByteReg.hasMatch(line[i]);
        if (isDoubleByte) {
          // print('数按字节字符---->${line[i]}');
        }
        canvas.drawRect(
          Rect.fromLTWH(
            _position.dx * letterWidth,
            _position.dy * letterHeight,
            isDoubleByte ? 2 * letterWidth : letterWidth,
            letterHeight,
          ),
          Paint()..color = Colors.black,
        );
        TextPainter painter = cache.getOrPerformLayout(
          TextSpan(
            text: line[i],
            style: curStyle,
          ),
        );
        painter
          ..layout(
            maxWidth: isDoubleByte ? 2 * letterWidth : letterWidth,
            minWidth: isDoubleByte ? 2 * letterWidth : letterWidth,
          )
          ..paint(
            canvas,
            Offset(
              _position.dx * letterWidth,
              _position.dy * letterHeight,
            ),
          );

        moveToNextOffset(1);
        if (isDoubleByte) {
          moveToNextOffset(1);
        }
      }
      if (j != outList.length - 1) {
        moveNewLineOffset();
      }
    }
    paintCursor(canvas);
    drawLine(canvas);
    lastLetterPositionCall?.call(
      _position.dy * letterHeight - termHeight + letterHeight,
    );
    controller.dirty = false;
    PrintUtil.printd(
      '${'<' * 32} $this defaultOffsetY->$defaultOffsetY',
      32,
    );
  }

  void paintCursor(Canvas canvas) {
    if (!isOutTerm() && showCursor) {
      canvas.drawRect(
        Rect.fromLTWH(_position.dx * letterWidth, _position.dy * letterHeight,
            letterWidth, letterHeight),
        Paint()..color = Colors.grey.withOpacity(0.4),
      );
    }
  }

  bool isOutTerm() {
    return _position.dy * letterHeight >= termHeight ||
        _position.dy * letterHeight < 0;
  }

  void moveToLineFirstOffset() {
    curPaintIndex = curPaintIndex - curPaintIndex % columnLength;
    _position = getCurPosition();
  }

  Position getCurPosition() {
    return Position(
      curPaintIndex % columnLength,
      curPaintIndex ~/ columnLength,
    );
  }

  void moveToNextOffset(int x) {
    curPaintIndex += x;
    _position = getCurPosition();
    // print(_position);
  }

  void moveNewLineOffset() {
    int tmp = columnLength - curPaintIndex % columnLength;
    curPaintIndex = tmp + curPaintIndex;
    _position = getCurPosition();
  }

  TextStyle getTextStyle(String tag, TextStyle preTextStyle) {
    switch (tag) {
      case '30':
        return preTextStyle.copyWith(
          color: theme.black,
        );
        break;
      case '31':
        return preTextStyle.copyWith(
          color: theme.red,
        );
        break;
      case '32':
        return preTextStyle.copyWith(
          color: theme.green,
        );
        break;
      case '33':
        return preTextStyle.copyWith(
          color: theme.yellow,
        );
        break;
      case '34':
        return preTextStyle.copyWith(
          color: theme.blue,
        );
        break;
      case '35':
        return preTextStyle.copyWith(
          color: theme.purplishRed,
        );
        break;
      case '36':
        return preTextStyle.copyWith(
          color: theme.cyan,
        );
        break;
      case '37':
        return preTextStyle.copyWith(
          color: theme.white,
        );
        break;
      case '42':
        return preTextStyle.copyWith(
          backgroundColor: theme.green,
        );
        break;
      case '49':
        return preTextStyle.copyWith(
          backgroundColor: theme.black,
          color: theme.defaultColor,
        );
        break;
      case '0':
        return preTextStyle.copyWith(
          color: theme.defaultColor,
          backgroundColor: Colors.transparent,
        );
        break;
      default:
        return preTextStyle;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
    return controller.dirty;
  }
}
