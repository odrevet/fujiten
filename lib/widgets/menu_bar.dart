import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../services/queries.dart';
import '../models/search.dart';
import '../string_utils.dart';
import 'radical_page.dart';
import 'settings.dart';

class MenuBar extends StatefulWidget {
  final Database? dbKanji;
  final Search? search;
  final TextEditingController? textEditingController;
  final VoidCallback onSearch;
  final Future<void> Function(String) setExpressionDb;
  final Future<void> Function(String) setKanjiDb;
  final KanjiKotobaButton kanjiKotobaButton;
  final ConvertButton convertButton;
  final int? insertPosition;
  final FocusNode focusNode;

  const MenuBar(
      {required this.dbKanji,
      required this.search,
      required this.textEditingController,
      required this.onSearch,
      required this.focusNode,
      required this.convertButton,
      required this.kanjiKotobaButton,
      required this.insertPosition,
      required this.setExpressionDb,
      required this.setKanjiDb,
      Key? key})
      : super(key: key);

  @override
  State<MenuBar> createState() => _MenuBarState();
}

class _MenuBarState extends State<MenuBar> {
  @override
  Widget build(BuildContext context) {
    var popupMenuButtonInsert = PopupMenuButton(
      icon: const Icon(Icons.input),
      onSelected: (dynamic result) {
        switch (result) {
          case 0:
            _displayRadicalWidget(context);
            break;
          case 1:
            if (widget.insertPosition! >= 0) {
              widget.textEditingController!.text = addCharAtPosition(
                  widget.textEditingController!.text, charKanji, widget.insertPosition);
              widget.textEditingController!.selection =
                  TextSelection.fromPosition(TextPosition(offset: widget.insertPosition! + 1));
            } else {
              widget.textEditingController!.text += charKanji;
            }
            break;
          case 2:
            if (widget.insertPosition! >= 0) {
              widget.textEditingController!.text = addCharAtPosition(
                  widget.textEditingController!.text, charKana, widget.insertPosition);
              widget.textEditingController!.selection =
                  TextSelection.fromPosition(TextPosition(offset: widget.insertPosition! + 1));
            } else {
              widget.textEditingController!.text += charKana;
            }
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0, child: Text('<> Radicals')),
        const PopupMenuItem(value: 1, child: Text('$charKanji Kanji')),
        const PopupMenuItem(value: 2, child: Text('$charKana Kana')),
      ],
    );

    return AppBar(
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => SettingsPage(
                          setExpressionDb: widget.setExpressionDb, setKanjiDb: widget.setKanjiDb)),
                )),
        Row(
          children: <Widget>[
            popupMenuButtonInsert,
            widget.convertButton,
            widget.kanjiKotobaButton,
            IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.textEditingController!.clear();
                  widget.search!.searchResults.clear();
                  widget.focusNode.requestFocus();
                }),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => widget.onSearch(),
            )
          ],
        ),
      ]),
    );
  }

  _displayRadicalWidget(BuildContext context) async {
    //send the radicals inside < > to the radical page
    var exp = RegExp(r'<(.*?)>');
    Iterable<RegExpMatch> matches = exp.allMatches(widget.textEditingController!.text);
    Match? matchAtCursor;
    for (Match m in matches) {
      if (widget.insertPosition! > m.start && widget.insertPosition! < m.end) {
        matchAtCursor = m;
        break;
      }
    }
    List<String> radicals =
        matchAtCursor == null ? [] : List.from(matchAtCursor.group(1)!.split(''));

    //remove every non-radical characters
    //call to getRadicalsCharacter somehow move the cursor to the end of textinput, retain de current position now
    int? insertPosition = 0;
    if (widget.insertPosition! > 0) insertPosition = widget.insertPosition;

    List<String?> radicalsFromDb = await getRadicalsCharacter(widget.dbKanji!);
    radicals.removeWhere((String radical) => !radicalsFromDb.contains(radical));

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RadicalPage(widget.dbKanji, radicals)),
    ).then((selectedRadicals) {
      if (selectedRadicals.isNotEmpty) {
        if (matchAtCursor == null) {
          widget.textEditingController!.text = addCharAtPosition(
              widget.textEditingController!.text, '<${selectedRadicals.join()}>', insertPosition);
        } else {
          widget.textEditingController!.text = widget.textEditingController!.text
              .replaceRange(matchAtCursor.start, matchAtCursor.end, '<${selectedRadicals.join()}>');
        }
      }

      //widget.textEditingController!.selection =
      //    TextSelection.fromPosition(TextPosition(offset: insertPosition!));
    });
  }
}

class KanjiKotobaButton extends StatefulWidget {
  final Function? onPressed;
  final bool? kanjiSearch;

  const KanjiKotobaButton({this.onPressed, this.kanjiSearch, Key? key}) : super(key: key);

  @override
  State<KanjiKotobaButton> createState() => _KanjiKotobaButtonState();
}

class _KanjiKotobaButtonState extends State<KanjiKotobaButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 70,
        child: TextButton(
            onPressed: widget.onPressed as void Function()?,
            child: Text(
              widget.kanjiSearch == true ? '漢字' : '言葉',
              style: const TextStyle(fontSize: 23.0, color: Colors.white),
            )));
  }
}

class ConvertButton extends StatefulWidget {
  final Function? onPressed;

  const ConvertButton({this.onPressed, Key? key}) : super(key: key);

  @override
  State<ConvertButton> createState() => _ConvertButtonState();
}

class _ConvertButtonState extends State<ConvertButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 70,
        child: IconButton(
            icon: const Icon(Icons.translate), onPressed: widget.onPressed as void Function()?));
  }
}
