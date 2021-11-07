// @dart=2.9

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kanji.dart';

class KanjiCharacteriWidget extends StatelessWidget {
  final Kanji kanji;
  final onTap;
  final bool displayFurigana;
  final String furigana;
  final TextStyle style;
  final TextStyle styleFurigana;

  KanjiCharacteriWidget(
      {this.kanji,
      this.onTap,
      this.displayFurigana = true,
      this.furigana,
      this.style,
      this.styleFurigana});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: furigana != null && displayFurigana
            ? Column(
                children: <Widget>[
                  Text(furigana, style: styleFurigana),
                  Expanded(child: Text(kanji.character, style: style))
                ],
              )
            : Text(kanji.character, style: style));
  }
}

class KanjiWidget extends StatelessWidget {
  final Kanji kanji;

  KanjiWidget(this.kanji);

  @override
  Widget build(BuildContext context) {
    String stroke = '${kanji.stroke.toString()} '
        'stroke${kanji.stroke > 1 ? 's' : ''}';
    String on = kanji.on == null ? '' : kanji.on.join('・');
    String kun = kanji.kun == null ? '' : kanji.kun.join('・');
    String radicals = kanji.radicals == null ? '' : kanji.radicals.join('');
    String meaning = kanji.meanings == null ? '' : kanji.meanings.join(', ');

    return ListTile(
        leading: KanjiCharacteriWidget(
            kanji: kanji,
            onTap: () =>
                Clipboard.setData(ClipboardData(text: kanji.character)),
            style: TextStyle(fontSize: 50.0)),
        title: Table(children: <TableRow>[
          TableRow(children: <Widget>[Text(stroke)]),
          TableRow(children: <Widget>[
            InkWell(
                child: Text(radicals),
                onTap: () => Clipboard.setData(ClipboardData(text: radicals)))
          ]),
          TableRow(children: <Widget>[Text(on)]),
          TableRow(children: <Widget>[Text(kun)]),
          TableRow(children: <Widget>[Text(meaning)])
        ]));
  }
}
