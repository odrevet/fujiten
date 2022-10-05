import 'package:flutter/material.dart';

import '../models/kanji.dart';
import 'kanji_widget.dart';

class KanjiListTile extends ListTile {
  final Kanji kanji;
  final Function()? onTapLeading;

  const KanjiListTile(
      {required this.kanji, required onTap, required selected, this.onTapLeading, Key? key})
      : super(key: key, onTap: onTap, selected: selected);

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
            onTap: onTapLeading,
            style: TextStyle(fontSize: 40.0, color: selected == true ? Colors.red : null)),
        onTap: onTap,
        title: Table(children: <TableRow>[
          TableRow(children: <Widget>[SelectableText(stroke)]),
          TableRow(children: <Widget>[SelectableText(radicals)]),
          TableRow(children: <Widget>[SelectableText(on)]),
          TableRow(children: <Widget>[SelectableText(kun)]),
          TableRow(children: <Widget>[SelectableText(meaning)])
        ]));
  }
}
