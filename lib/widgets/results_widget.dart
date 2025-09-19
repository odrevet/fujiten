import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:fujiten/widgets/database_status_display.dart';
import 'package:fujiten/widgets/result_expression_list.dart';
import 'package:flutter/material.dart';

import '../cubits/input_cubit.dart';
import '../models/entry.dart';
import '../models/search.dart';
import 'kanji_list_tile.dart';

class ResultsWidget extends StatefulWidget {
  final Function onEndReached;

  const ResultsWidget(this.onEndReached, {super.key});

  @override
  State<ResultsWidget> createState() => _ResultsWidgetState();
}

class _ResultsWidgetState extends State<ResultsWidget> with AutomaticKeepAliveClientMixin {
  ScrollController? _scrollController;

  // This keeps the widget state alive when switching tabs
  @override
  bool get wantKeepAlive => true;

  @override
  initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController!.addListener(scrollListener);
  }

  @override
  void dispose() {
    _scrollController!.dispose();
    super.dispose();
  }

  void scrollListener() {
    if (_scrollController!.offset >=
        _scrollController!.position.maxScrollExtent &&
        !_scrollController!.position.outOfRange &&
        !context.read<SearchCubit>().state.isLoading &&
        !context.read<SearchCubit>().state.isLoadingNextPage) {
      widget.onEndReached();
    }
  }

  Widget itemBuilderExpression(BuildContext context, int index, Search search) {
    if (search.searchResults[index] is KanjiEntry) {
      KanjiEntry searchResult = search.searchResults[index] as KanjiEntry;
      return KanjiListTile(
        kanji: searchResult.kanji,
        selected: false,
        onTap: () =>
            Clipboard.setData(ClipboardData(text: searchResult.kanji.literal)),
      );
    } else {
      final expressionResults = search.searchResults
          .whereType<ExpressionEntry>()
          .toList();

      return ResultExpressionList(searchResult: expressionResults[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Call super.build to maintain the keep alive state
    super.build(context);

    return BlocBuilder<SearchCubit, Search>(
      builder: (context, search) {
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
            child = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  "No results found",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "for '${context.read<InputCubit>().state.inputs[context.read<InputCubit>().state.searchIndex]}'",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          } else {
            if (context
                .read<InputCubit>()
                .state
                .inputs[context.read<InputCubit>().state.searchIndex]
                .isEmpty) {
              // Center the DatabaseStatusDisplay vertically
              child = Center(child: DatabaseStatusDisplay());
            } else {
              child = ListView.builder(
                controller: _scrollController,
                itemCount: search.searchResults.length,
                itemBuilder: (BuildContext context, int index) {
                  return itemBuilderExpression(context, index, search);
                },
              );
            }
          }
        }

        return Center(child: child);
      },
    );
  }
}