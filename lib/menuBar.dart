

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'settings.dart';
import 'queries.dart';
import 'radicalPage.dart';
import 'search.dart';
import 'stringUtils.dart';

class LanguageSelect extends StatefulWidget {
  final void Function(String?)? onLanguageSelect;

  LanguageSelect({Key? key, this.onLanguageSelect}) : super(key: key);

  @override
  _LanguageSelectState createState() => _LanguageSelectState();
}

class _LanguageSelectState extends State<LanguageSelect> {
  String? dropdownValue = 'eng';

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      icon: Icon(Icons.language),
      onChanged: (String? lang) {
        widget.onLanguageSelect!(lang);
        setState(() {
          dropdownValue = lang;
        });
      },
      items: <String>[
        'eng',
        'fre',
        'rus',
        'swe',
        'spa',
        'slv',
        'ger',
        'dut',
        'hun'
      ].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }
}

class MenuBar extends StatefulWidget {
  final Database? dbKanji;
  final Search? search;
  final TextEditingController? textEditingController;
  final VoidCallback? onSearch;
  final void Function(String?)? onLanguageSelect;
  final kanjiKotobaButton;
  final int? insertPosition;

  MenuBar(
      {this.dbKanji,
      this.search,
      this.textEditingController,
      this.onSearch,
      this.onLanguageSelect,
      this.kanjiKotobaButton,
      this.insertPosition});

  @override
  _MenuBarState createState() => _MenuBarState();
}

class _MenuBarState extends State<MenuBar> {
  @override
  Widget build(BuildContext context) {
    var popupMenuButtonInsert = PopupMenuButton(
      icon: Icon(Icons.input),
      onSelected: (dynamic result) {
        switch (result) {
          case 0:
            _displayRadicalWidget(context);
            break;
          case 1:
            if (widget.insertPosition! >= 0) {
              widget.textEditingController!.text = addCharAtPosition(
                  widget.textEditingController!.text,
                  charKanji,
                  widget.insertPosition);
              widget.textEditingController!.selection =
                  TextSelection.fromPosition(
                      TextPosition(offset: widget.insertPosition! + 1));
            } else
              widget.textEditingController!.text += charKanji;
            break;
          case 2:
            if (widget.insertPosition! >= 0) {
              widget.textEditingController!.text = addCharAtPosition(
                  widget.textEditingController!.text,
                  charKana,
                  widget.insertPosition);
              widget.textEditingController!.selection =
                  TextSelection.fromPosition(
                      TextPosition(offset: widget.insertPosition! + 1));
            } else
              widget.textEditingController!.text += charKana;
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(child: Text('<> Radicals'), value: 0),
        PopupMenuItem(child: Text('$charKanji Kanji'), value: 1),
        PopupMenuItem(child: Text('$charKana Kana'), value: 2),
      ],
    );

    return AppBar(
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                )),
        Row(
          children: <Widget>[
            LanguageSelect(
              onLanguageSelect: widget.onLanguageSelect,
            ),
            popupMenuButtonInsert,
            widget.kanjiKotobaButton,
            VerticalDivider(
              color: Colors.white,
              thickness: 1.0,
            ),
            IconButton(
                icon: Icon(Icons.clear),
                onPressed: () {
                  widget.textEditingController!.clear();
                  widget.search!.searchResults.clear();
                }),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () => widget.onSearch!(),
            )
          ],
        ),
      ]),
    );
  }

  _displayRadicalWidget(BuildContext context) async {
    //send the radicals inside < > to the radical page
    var exp = RegExp(r'<(.*?)>');
    Iterable<RegExpMatch> matches =
        exp.allMatches(widget.textEditingController!.text);
    Match? matchAtCursor;
    for (Match m in matches) {
      if (widget.insertPosition! > m.start && widget.insertPosition! < m.end) {
        matchAtCursor = m;
        break;
      }
    }
    List<String> radicals = matchAtCursor == null
        ? []
        : List.from(matchAtCursor.group(1)!.split(''));

    //remove every non-radical characters
    //call to getRadicalsCharacter somehow move the cursor to the end of textinput, retain de current position now
    int? insertPosition = 0;
    if (widget.insertPosition! > 0) insertPosition = widget.insertPosition;

    List<String?> radicalsFromDb = await getRadicalsCharacter(widget.dbKanji!);
    radicals.removeWhere((String radical) => !radicalsFromDb.contains(radical));

    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => RadicalPage(widget.dbKanji, radicals)),
    ).then((selectedRadicals) {
      if (selectedRadicals.isNotEmpty) {
        if (matchAtCursor == null) {
          widget.textEditingController!.text = addCharAtPosition(
              widget.textEditingController!.text,
              '<${selectedRadicals.join()}>',
              insertPosition);
        } else {
          widget.textEditingController!.text = widget.textEditingController!.text
              .replaceRange(matchAtCursor.start, matchAtCursor.end,
                  '<${selectedRadicals.join()}>');
        }
      }

      widget.textEditingController!.selection =
          TextSelection.fromPosition(TextPosition(offset: insertPosition!));
    });
  }
}

class KanjiKotobaButton extends StatefulWidget {
  final Function? onPressed;
  final bool? kanjiSearch;

  KanjiKotobaButton({this.onPressed, this.kanjiSearch});

  @override
  _KanjiKotobaButtonState createState() => _KanjiKotobaButtonState();
}

class _KanjiKotobaButtonState extends State<KanjiKotobaButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 70,
        child: TextButton(
            child: Text(
              widget.kanjiSearch == true ? '漢字' : '言葉',
              style: TextStyle(fontSize: 23.0, color: Colors.white),
            ),
            onPressed: widget.onPressed as void Function()?));
  }
}
