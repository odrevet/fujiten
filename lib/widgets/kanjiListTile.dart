import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/kanji.dart';
import 'kanji_widget.dart';

class KanjiListTile extends StatelessWidget {
  final Kanji kanji;
  final Function? onTap;

  const KanjiListTile({required this.kanji, this.onTap, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String stroke = '${kanji.strokeCount.toString()} '
        'stroke${kanji.strokeCount > 1 ? 's' : ''}';
    String on = kanji.on == null ? '' : kanji.on!.join('・');
    String kun = kanji.kun == null ? '' : kanji.kun!.join('・');
    String radicals = kanji.radicals == null ? '' : kanji.radicals!.join('');
    String meaning = kanji.meanings == null ? '' : kanji.meanings!.join(', ');

    return ListTile(
        leading: KanjiCharacterWidget(
            kanji: kanji,
            style: const TextStyle(fontSize: 40.0)),
        onTap: () => onTap != null ? onTap!(kanji.literal) : null,
        title: Table(children: <TableRow>[
          TableRow(children: <Widget>[Text(stroke)]),
          TableRow(children: <Widget>[
            InkWell(
                child: Text(radicals),
                /*onTap: () => Clipboard.setData(ClipboardData(text: radicals))*/)
          ]),
          TableRow(children: <Widget>[Text(on)]),
          TableRow(children: <Widget>[Text(kun)]),
          TableRow(children: <Widget>[Text(meaning)])
        ]));
  }
}
