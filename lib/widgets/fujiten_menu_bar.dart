import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/expression_cubit.dart';
import '../cubits/input_cubit.dart';
import '../cubits/kanji_cubit.dart';
import '../cubits/search_options_cubit.dart';
import '../models/search.dart';
import '../models/states/search_options_state.dart';
import '../string_utils.dart';
import 'radical_page.dart';
import 'search_input.dart';
import 'settings/settings.dart';

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
                addStringInController(
                  searchOptionsState.useRegexp ? '.*' : '*',
                );
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
              child: Text(
                '${searchOptionsState.useRegexp ? ".*" : "*"} Anything',
              ),
            ),
          ],
        );

        var popupMenuButtonInputs = PopupMenuButton(
          icon: const Icon(Icons.list),
          onSelected: (dynamic result) {
            if (result == "add") {
              context.read<InputCubit>().addInput();
              int searchIndex =
                  context.read<InputCubit>().state.inputs.length - 1;
              context.read<InputCubit>().setSearchIndex(searchIndex);
              widget.textEditingController!.text = context
                  .read<InputCubit>()
                  .state
                  .inputs[searchIndex];
            } else if (result == "remove") {
              context.read<InputCubit>().removeInput();
              widget.textEditingController!.text = context
                  .read<InputCubit>()
                  .state
                  .inputs[context.read<InputCubit>().state.searchIndex];
            } else if (result == "clear") {
              widget.textEditingController!.clear();
              context.read<InputCubit>().state.inputs[context
                      .read<InputCubit>()
                      .state
                      .searchIndex] =
                  "";
              widget.focusNode.requestFocus();
            } else {
              context.read<InputCubit>().setSearchIndex(result);
              widget.textEditingController!.text = context
                  .read<InputCubit>()
                  .state
                  .inputs[result];
            }
          },
          itemBuilder: (itemBuilderContext) =>
              context
                  .read<InputCubit>()
                  .state
                  .inputs
                  .asMap()
                  .entries
                  .map<PopupMenuEntry<dynamic>>(
                    (entry) => PopupMenuItem(
                      value: entry.key,
                      child: ListTile(
                        leading: Text(entry.key.toString()),
                        title: Text(entry.value),
                        selected:
                            entry.key ==
                            context.read<InputCubit>().state.searchIndex,
                      ),
                    ),
                  )
                  .toList()
                ..add(
                  const PopupMenuItem(
                    value: "add",
                    child: ListTile(
                      leading: Icon(Icons.add),
                      title: Text('Add'),
                    ),
                  ),
                )
                ..add(
                  PopupMenuItem(
                    value: "remove",
                    enabled: context.read<InputCubit>().state.inputs.length > 1,
                    child: ListTile(
                      enabled:
                          context.read<InputCubit>().state.inputs.length > 1,
                      leading: const Icon(Icons.remove),
                      title: const Text('Remove'),
                    ),
                  ),
                )
                ..add(
                  PopupMenuItem(
                    value: "clear",
                    enabled: widget.textEditingController!.text != "",
                    child: ListTile(
                      enabled: widget.textEditingController!.text != "",
                      leading: const Icon(Icons.clear),
                      title: const Text('Clear'),
                    ),
                  ),
                ),
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
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () =>
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsPage()),
                    ).then((_) {
                      if (context.mounted) {
                        context.read<ExpressionCubit>().refreshDatabaseStatus();
                        context.read<KanjiCubit>().refreshDatabaseStatus();
                      }
                    }),
              ),
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
