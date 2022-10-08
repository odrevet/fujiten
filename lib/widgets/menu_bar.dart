import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:fujiten/services/database_interface_kanji.dart';
import 'package:fujiten/widgets/toggle_search_type_button.dart';

import '../models/search.dart';
import '../string_utils.dart';
import 'radical_page.dart';
import 'settings/settings.dart';

class MenuBar extends StatefulWidget {
  final DatabaseInterfaceKanji databaseInterfaceKanji;
  final Search? search;
  final TextEditingController? textEditingController;
  final VoidCallback onSearch;
  final Future<void> Function(String) setExpressionDb;
  final Future<void> Function(String) setKanjiDb;
  final VoidCallback checkDb;
  final int insertPosition;
  final FocusNode focusNode;

  const MenuBar(
      {required this.databaseInterfaceKanji,
      required this.search,
      required this.textEditingController,
      required this.onSearch,
      required this.focusNode,
      required this.insertPosition,
      required this.setExpressionDb,
      required this.setKanjiDb,
      required this.checkDb,
      Key? key})
      : super(key: key);

  @override
  State<MenuBar> createState() => _MenuBarState();
}

class _MenuBarState extends State<MenuBar> {
  addStringInController(String input) {
    if (widget.insertPosition >= 0) {
      widget.textEditingController!.text =
          addCharAtPosition(widget.textEditingController!.text, input, widget.insertPosition);
      widget.textEditingController!.selection =
          TextSelection.fromPosition(TextPosition(offset: widget.insertPosition + 1));
    } else {
      widget.textEditingController!.text += input;
    }
  }

  convert() {
    String? input = widget.textEditingController?.text;
    if (kanaKit.isRomaji(input!)) {
      widget.textEditingController?.text = kanaKit.toKana(input);
    } else if (kanaKit.isHiragana(input)) {
      widget.textEditingController?.text = kanaKit.toKatakana(input);
    } else if (kanaKit.isKatakana(input)) {
      widget.textEditingController?.text = kanaKit.toRomaji(input);
    } else {
      // mixed string
      widget.textEditingController?.text = kanaKit.toKana(input);
    }
  }

  @override
  Widget build(BuildContext context) {
    var popupMenuButtonInsert = PopupMenuButton(
      icon: const Icon(Icons.input),
      onSelected: (dynamic result) {
        switch (result) {
          case 0:
            displayRadicalWidget(context);
            break;
          case 1:
            addStringInController(charKanji);
            break;
          case 2:
            addStringInController(charKana);
            break;
          case 3:
            addStringInController('.*');
            break;
        }
        context.read<SearchCubit>().setInput(widget.textEditingController!.text);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0, child: Text('<> Radicals')),
        const PopupMenuItem(value: 1, child: Text('$charKanji Kanji')),
        const PopupMenuItem(value: 2, child: Text('$charKana Kana')),
        const PopupMenuItem(value: 3, child: Text('.* Anything')),
      ],
    );

    var popupMenuButtonInputs = PopupMenuButton(
      icon: const Icon(Icons.list),
      onSelected: (dynamic result) {
        if (result == "add") {
          context.read<SearchCubit>().addInput();
          int searchIndex = context.read<SearchCubit>().state.inputs.length - 1;
          context.read<SearchCubit>().setSearchIndex(searchIndex);
          widget.textEditingController!.text =
              context.read<SearchCubit>().state.inputs[searchIndex];
        } else if (result == "remove") {
          context.read<SearchCubit>().removeInput(context.read<SearchCubit>().state.searchIndex);
          int searchIndex = context.read<SearchCubit>().state.searchIndex--;
          context.read<SearchCubit>().setSearchIndex(searchIndex);
          widget.textEditingController!.text =
              context.read<SearchCubit>().state.inputs[searchIndex];
        } else if (result == "clear") {
          widget.textEditingController!.clear();
          widget.focusNode.requestFocus();
        } else {
          context.read<SearchCubit>().setSearchIndex(result);
          widget.textEditingController!.text = context.read<SearchCubit>().state.inputs[result];
        }
      },
      itemBuilder: (itemBuilderContext) => context
          .read<SearchCubit>()
          .state
          .inputs
          .asMap()
          .entries
          .map<PopupMenuEntry<dynamic>>((entry) => PopupMenuItem(
              value: entry.key,
              child: Text("${entry.key}   ${entry.value}",
                  style: entry.key == context.read<SearchCubit>().state.searchIndex
                      ? const TextStyle(color: Colors.blue)
                      : null)))
          .toList()
        ..add(const PopupMenuItem(value: "add", child: Text("+ New input")))
        ..add(PopupMenuItem(
            value: "remove",
            enabled: context.read<SearchCubit>().state.inputs.length > 1,
            child: const Text("- Remove input")))
        ..add(PopupMenuItem(
            value: "clear",
            enabled: widget.textEditingController!.text != "",
            child: const Text("x Clear input"))),
    );

    return AppBar(
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SettingsPage(
                            setExpressionDb: widget.setExpressionDb,
                            setKanjiDb: widget.setKanjiDb))).then((_) {
                  widget.checkDb();
                })),
        Row(
          children: <Widget>[
            popupMenuButtonInsert,
            IconButton(icon: const Icon(Icons.translate), onPressed: convert),
            const ToggleSearchTypeButton(),
            /*IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  widget.textEditingController!.clear();
                  widget.search!.searchResults.clear();
                  //widget.search!.input = '';
                  widget.focusNode.requestFocus();
                }),*/
            popupMenuButtonInputs,
            /*IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => widget.onSearch(),
            )*/
          ],
        ),
      ]),
    );
  }

  displayRadicalWidget(BuildContext context) async {
    //send the radicals inside < > to the radical page
    var exp = RegExp(r'<(.*?)>');
    Iterable<RegExpMatch> matches = exp.allMatches(widget.textEditingController!.text);
    Match? matchAtCursor;
    for (Match m in matches) {
      if (widget.insertPosition > m.start && widget.insertPosition < m.end) {
        matchAtCursor = m;
        break;
      }
    }
    List<String> radicals =
        matchAtCursor == null ? [] : List.from(matchAtCursor.group(1)!.split(''));

    //remove every non-radical characters
    //call to getRadicalsCharacter somehow move the cursor to the end of textinput, retain de current position now
    int insertPosition = 0;
    if (widget.insertPosition > 0) insertPosition = widget.insertPosition;

    List<String?> radicalsFromDb = await widget.databaseInterfaceKanji.getRadicalsCharacter();
    radicals.removeWhere((String radical) => !radicalsFromDb.contains(radical));

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RadicalPage(widget.databaseInterfaceKanji, radicals)),
    ).then((results) {
      var isRadicalList = results[0];
      var selectedRadicalsOrKanji = results[1];
      if (isRadicalList) {
        if (selectedRadicalsOrKanji.isNotEmpty) {
          if (matchAtCursor == null) {
            widget.textEditingController!.text = addCharAtPosition(
                widget.textEditingController!.text,
                '<${selectedRadicalsOrKanji.join()}>',
                insertPosition);
          } else {
            widget.textEditingController!.text = widget.textEditingController!.text.replaceRange(
                matchAtCursor.start, matchAtCursor.end, '<${selectedRadicalsOrKanji.join()}>');
          }
        }
      } else {
        if (matchAtCursor == null) {
          widget.textEditingController!.text = addCharAtPosition(
              widget.textEditingController!.text, selectedRadicalsOrKanji, insertPosition);
        } else {
          widget.textEditingController!.text = widget.textEditingController!.text
              .replaceRange(matchAtCursor.start, matchAtCursor.end, selectedRadicalsOrKanji);
        }
      }

      context.read<SearchCubit>().setInput(widget.textEditingController!.text);
    });
  }
}
