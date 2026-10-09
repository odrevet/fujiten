import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/input_cubit.dart';
import '../cubits/kanji_cubit.dart';
import '../cubits/search_options_cubit.dart';
import '../models/search.dart';
import '../models/states/search_options_state.dart';
import '../string_utils.dart';
import 'radical_page.dart';
import 'search_input.dart';
import 'session_menu.dart';

class FujitenMenuBar extends StatefulWidget {
  final Search? search;
  final TextEditingController? textEditingController;
  final VoidCallback onSearch;
  final int insertPosition;
  final FocusNode focusNode;
  final VoidCallback onToggleSearchType;
  final SearchType currentSearchType;
  final VoidCallback? onConvert;

  const FujitenMenuBar({
    required this.search,
    required this.textEditingController,
    required this.onSearch,
    required this.focusNode,
    required this.insertPosition,
    required this.onToggleSearchType,
    required this.currentSearchType,
    required this.onConvert,
    super.key,
  });

  @override
  State<FujitenMenuBar> createState() => _FujitenMenuBarState();
}

class _FujitenMenuBarState extends State<FujitenMenuBar> {
  void addStringInController(String input) {
    if (widget.insertPosition >= 0) {
      widget.textEditingController!.text = addCharAtPosition(
        widget.textEditingController!.text,
        input,
        widget.insertPosition,
      );
      widget.textEditingController!.selection = TextSelection.fromPosition(
        TextPosition(offset: widget.insertPosition + 1),
      );
    } else {
      widget.textEditingController!.text += input;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return BlocBuilder<SearchOptionsCubit, SearchOptionsState>(
      builder: (context, searchOptionsState) {
        final currentMode = widget.currentSearchType == SearchType.expression
            ? searchOptionsState.expressionSearchMode
            : searchOptionsState.kanjiSearchMode;
        final wildcard = currentMode == SearchMode.regexp
            ? '.*'
            : (currentMode == SearchMode.glob ? '*' : null);

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
                if (wildcard != null) addStringInController(wildcard);
                break;
            }
            context.read<InputCubit>().setInput(
              widget.textEditingController!.text,
            );
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 0, child: Text('<> Radicals')),
            const PopupMenuItem(value: 1, child: Text('$charKanji Kanji')),
            const PopupMenuItem(value: 2, child: Text('$charKana Kana')),
            PopupMenuItem(
              value: 3,
              enabled: wildcard != null,
              child: Text(
                wildcard == null ? 'Anything' : '$wildcard Anything',
              ),
            ),
          ],
        );

        var popupMenuButtonInputs = SessionMenu(
          textEditingController: widget.textEditingController!,
          onSearch: widget.onSearch,
        );

        Widget searchTypeToggle = IconButton(
          icon: Text(
            widget.currentSearchType == SearchType.expression ? '言' : '漢',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          onPressed: () {
            final newSearchType =
                widget.currentSearchType == SearchType.expression
                ? SearchType.kanji
                : SearchType.expression;
            context.read<SearchOptionsCubit>().setSearchType(newSearchType);
          },
        );

        return AppBar(
          title: Row(
            children: [
              if (isLandscape)
                Expanded(
                  child: SearchInput(
                    widget.textEditingController!,
                    widget.onSearch,
                    (_) {},
                    widget.focusNode,
                    onConvert: widget.onConvert,
                  ),
                )
              else
                const Spacer(), // keeps icons on the right in portrait
              popupMenuButtonInsert,
              IconButton(
                icon: const Icon(Icons.translate),
                onPressed: widget.onConvert,
              ),
              popupMenuButtonInputs,
              searchTypeToggle,
            ],
          ),
        );
      },
    );
  }

  Future<void> displayRadicalWidget(BuildContext context) async {
    var exp = RegExp(r'<(.*?)>');
    Iterable<RegExpMatch> matches = exp.allMatches(
      widget.textEditingController!.text,
    );
    Match? matchAtCursor;
    for (Match m in matches) {
      if (widget.insertPosition > m.start && widget.insertPosition < m.end) {
        matchAtCursor = m;
        break;
      }
    }
    List<String> radicals = matchAtCursor == null
        ? []
        : List.from(matchAtCursor.group(1)!.split(''));

    int insertPosition = 0;
    if (widget.insertPosition > 0) insertPosition = widget.insertPosition;

    List<String?> radicalsFromDb = await context
        .read<KanjiCubit>()
        .databaseInterface
        .getRadicalsCharacter();
    radicals.removeWhere((String radical) => !radicalsFromDb.contains(radical));

    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RadicalPage(radicals)),
    ).then((results) {
      var isRadicalList = results[0];
      var selectedRadicalsOrKanji = results[1];
      if (isRadicalList) {
        if (selectedRadicalsOrKanji.isNotEmpty) {
          if (matchAtCursor == null) {
            widget.textEditingController!.text = addCharAtPosition(
              widget.textEditingController!.text,
              '<${selectedRadicalsOrKanji.join()}>',
              insertPosition,
            );
          } else {
            widget.textEditingController!.text = widget
                .textEditingController!
                .text
                .replaceRange(
                  matchAtCursor.start,
                  matchAtCursor.end,
                  '<${selectedRadicalsOrKanji.join()}>',
                );
          }
        }
      } else {
        if (matchAtCursor == null) {
          widget.textEditingController!.text = addCharAtPosition(
            widget.textEditingController!.text,
            selectedRadicalsOrKanji,
            insertPosition,
          );
        } else {
          widget.textEditingController!.text = widget
              .textEditingController!
              .text
              .replaceRange(
                matchAtCursor.start,
                matchAtCursor.end,
                selectedRadicalsOrKanji,
              );
        }
      }

      if (context.mounted) {
        context.read<InputCubit>().setInput(widget.textEditingController!.text);
      }
    });
  }
}
