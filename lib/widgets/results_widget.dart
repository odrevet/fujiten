import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:fujiten/services/database_interface_kanji.dart';
import 'package:fujiten/widgets/database_status_display.dart';

import '../cubits/input_cubit.dart';
import '../models/entry.dart';
import '../models/kanji.dart';
import '../models/search.dart';
import '../models/sense.dart';
import '../services/database_interface_expression.dart';
import '../string_utils.dart' show kanaKit;
import 'kanji_list_tile.dart';

class ResultsWidget extends StatefulWidget {
  final DatabaseInterfaceKanji databaseInterfaceKanji;
  final DatabaseInterfaceExpression databaseInterfaceExpression;
  final Function onEndReached;

  const ResultsWidget(
      this.databaseInterfaceKanji, this.databaseInterfaceExpression, this.onEndReached,
      {Key? key})
      : super(key: key);

  @override
  State<ResultsWidget> createState() => _ResultsWidgetState();
}

class _ResultsWidgetState extends State<ResultsWidget> {
  ScrollController? _scrollController;
  TextStyle? _styleFieldInformation;

  @override
  initState() {
    _scrollController = ScrollController();
    _scrollController!.addListener(scrollListener);

    _styleFieldInformation =
        const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.blue);

    super.initState();
  }

  @override
  void dispose() {
    _scrollController!.dispose();
    super.dispose();
  }

  scrollListener() {
    if (_scrollController!.offset >= _scrollController!.position.maxScrollExtent &&
        !_scrollController!.position.outOfRange &&
        !context.read<SearchCubit>().state.isLoading &&
        !context.read<SearchCubit>().state.isLoadingNextPage) {
      widget.onEndReached();
    }
  }

  Widget buildResultKanji(result) {
    return KanjiListTile(
        kanji: result.kanji,
        selected: false,
        onTap: () => Clipboard.setData(ClipboardData(text: result.kanji.literal)));
  }

  Widget buildResultExpression(searchResult) {
    //group glosses by pos
    Map sensesGroupedByPosses = <String?, List<Sense>>{};
    searchResult.senses.forEach((sense) {
      String? posString = sense.posses.join(', ');
      if (!sensesGroupedByPosses.containsKey(posString)) {
        sensesGroupedByPosses[posString] = <Sense>[];
      }
      sensesGroupedByPosses[posString].add(sense);
    });

    /// filter reading to keep only kanji characters
    List<String> literals = [];
    for (int i = 0; i < searchResult.reading[0].length; i++) {
      if (kanaKit.isKanji(searchResult.reading[0][i])) {
        literals.add(searchResult.reading[0][i]);
      }
    }

    return ListTile(
        title: Column(
      children: <Widget>[
        InkWell(
          onTap: () => literals.isNotEmpty
              ? showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                        title: const Center(child: Text('Kanji')),
                        content: _kanjiDialogContent(literals),
                      ))
              : null,
          onDoubleTap: () => Clipboard.setData(ClipboardData(text: searchResult.reading)),
          child: Text(
            '${searchResult.reading.isNotEmpty ? searchResult.reading[0] : ''}',
            style: const TextStyle(fontSize: 20.0),
          ),
        ),
        // Other japanese reading forms
        Wrap(
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: searchResult.reading.skip(1).map<Widget>((reading) {
                  List<String> literals = [];
                  for (int i = 0; i < reading.length; i++) {
                    if (kanaKit.isKanji(reading[i])) {
                      literals.add(reading[i]);
                    }
                  }
                  return InkWell(
                      onTap: () => literals.isNotEmpty
                          ? showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                    title: const Center(child: Text('Kanji')),
                                    content: _kanjiDialogContent(literals),
                                  ))
                          : null,
                      child: Text(" $reading ", style: const TextStyle(fontSize: 16.0)));
                }).toList())
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sensesGroupedByPosses.entries.map((glossesGroupedByPos) {
              String? pos = glossesGroupedByPos.key;
              List<Sense> senses = glossesGroupedByPos.value;

              return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: RichText(
                    text: TextSpan(
                        text: '• $pos\n',
                        style: _styleFieldInformation,
                        children: List.generate(glossesGroupedByPos.value.length, (i) {
                          return TextSpan(
                              text: senses[i].glosses.join(","),
                              style: Theme.of(context).textTheme.bodyText2,
                              children: [
                                TextSpan(
                                    text: " ${senses[i].dial.join(",")}",
                                    style: _styleFieldInformation),
                                TextSpan(
                                    text: " ${senses[i].misc.join(",")}",
                                    style: _styleFieldInformation),
                                const TextSpan(text: "\n")
                              ]);
                        })),
                  ));
            }).toList(),
          ),
        ),
      ],
    ));
  }

  Widget _kanjiDialogContent(List<String> literals) {
    return SizedBox(
      width: double.maxFinite,
      child: FutureBuilder<List<Kanji>>(
          future: widget.databaseInterfaceKanji.getCharactersFromLiterals(literals),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final List<Kanji> sortedCharacters = List.from(snapshot.data!)
                ..sort((a, b) => literals.indexOf(a.literal) - literals.indexOf(b.literal));
              return ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (context, index) {
                    return const Divider();
                  },
                  itemCount: sortedCharacters.length,
                  itemBuilder: (BuildContext context, int index) {
                    return KanjiListTile(
                        onTap: null,
                        onTapLeading: () =>
                            Clipboard.setData(ClipboardData(text: sortedCharacters[index].literal)),
                        selected: false,
                        kanji: sortedCharacters[index]);
                  });
            } else if (snapshot.hasError) {
              return ListTile(title: Text("${snapshot.error}"));
            }

            return ListView(
              shrinkWrap: true,
              children: const [ListTile(title: Center(child: CircularProgressIndicator()))],
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, Search>(builder: (context, search) {
      late Widget child;

      if (search.isLoading && !search.isLoadingNextPage) {
        child = const CircularProgressIndicator();
      } else {
        if (search.searchResults.isEmpty &&
            context
                .read<InputCubit>()
                .state
                .inputs[context.read<InputCubit>().state.searchIndex]
                .isNotEmpty) {
          child = Text(
              "No results for '${context.read<InputCubit>().state.inputs[context.read<InputCubit>().state.searchIndex]}'");
        } else {
          if (context
              .read<InputCubit>()
              .state
              .inputs[context.read<InputCubit>().state.searchIndex]
              .isEmpty) {
            child = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Welcome to Fujiten",
                  style: TextStyle(fontSize: 18),
                ),
                ElevatedButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                                title: const Center(child: Text('Databases Status')),
                                content: DatabaseStatusDisplay(
                                  databaseInterfaceExpression: widget.databaseInterfaceExpression,
                                  databaseInterfaceKanji: widget.databaseInterfaceKanji,
                                ),
                              ));
                    },
                    child: const Text("Check DB status"))
              ],
            );
          } else {
            child = ListView.separated(
                separatorBuilder: (context, index) {
                  return const Divider();
                },
                controller: _scrollController,
                itemCount: search.searchResults.length,
                itemBuilder: (BuildContext context, int index) {
                  if (search.searchResults[index] is KanjiEntry) {
                    KanjiEntry searchResult = search.searchResults[index] as KanjiEntry;
                    return buildResultKanji(searchResult);
                  } else {
                    return buildResultExpression(search.searchResults[index]);
                  }
                });
          }
        }
      }
      return Expanded(child: Center(child: child));
    });
  }
}
