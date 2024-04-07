import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:fujiten/services/database_interface_kanji.dart';
import 'package:fujiten/widgets/database_status_display.dart';
import 'package:fujiten/widgets/result_expression_list.dart';

import '../cubits/input_cubit.dart';
import '../models/entry.dart';
import '../models/search.dart';
import '../services/database_interface_expression.dart';
import 'kanji_list_tile.dart';

class ResultsWidget extends StatefulWidget {
  final DatabaseInterfaceKanji databaseInterfaceKanji;
  final DatabaseInterfaceExpression databaseInterfaceExpression;
  final Function onEndReached;

  const ResultsWidget(this.databaseInterfaceKanji,
      this.databaseInterfaceExpression, this.onEndReached,
      {Key? key})
      : super(key: key);

  @override
  State<ResultsWidget> createState() => _ResultsWidgetState();
}

class _ResultsWidgetState extends State<ResultsWidget> {
  ScrollController? _scrollController;

  @override
  initState() {
    _scrollController = ScrollController();
    _scrollController!.addListener(scrollListener);

    super.initState();
  }

  @override
  void dispose() {
    _scrollController!.dispose();
    super.dispose();
  }

  scrollListener() {
    if (_scrollController!.offset >=
            _scrollController!.position.maxScrollExtent &&
        !_scrollController!.position.outOfRange &&
        !context.read<SearchCubit>().state.isLoading &&
        !context.read<SearchCubit>().state.isLoadingNextPage) {
      widget.onEndReached();
    }
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
                      Future.wait([
                        widget.databaseInterfaceKanji.setStatus(),
                        widget.databaseInterfaceExpression.setStatus()
                      ]).then((List responses) => showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                                title: const Center(
                                    child: Text('Databases Status')),
                                content: DatabaseStatusDisplay(
                                  databaseInterfaceExpression:
                                      widget.databaseInterfaceExpression,
                                  databaseInterfaceKanji:
                                      widget.databaseInterfaceKanji,
                                ),
                              )));
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
                    KanjiEntry searchResult =
                        search.searchResults[index] as KanjiEntry;
                    return KanjiListTile(
                        kanji: searchResult.kanji,
                        selected: false,
                        onTap: () => Clipboard.setData(
                            ClipboardData(text: searchResult.kanji.literal)));
                  } else {
                    return ResultExpressionList(
                        searchResult: search.searchResults[index],
                        databaseInterfaceKanji: widget.databaseInterfaceKanji);
                  }
                });
          }
        }
      }
      return Expanded(child: Center(child: child));
    });
  }
}
