import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:fujiten/widgets/database_status_display.dart';
import 'package:fujiten/widgets/result_expression_list.dart';

import '../cubits/search_options_cubit.dart';
import '../models/entry.dart';
import '../models/search.dart';
import '../models/states/search_options_state.dart';
import 'kanji_list_tile.dart';

class ResultsWidget extends StatefulWidget {
  final Function onEndReached;
  final TextEditingController? textEditingController;
  final VoidCallback? onSearch;

  const ResultsWidget(
      this.onEndReached, {
        super.key,
        this.textEditingController,
        this.onSearch,
      });

  @override
  State<ResultsWidget> createState() => _ResultsWidgetState();
}

class _ResultsWidgetState extends State<ResultsWidget>
    with AutomaticKeepAliveClientMixin {
  ScrollController? _scrollController;

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

  String _getWildcardSequence() {
    final searchOptions = context.read<SearchOptionsCubit>().state;
    return searchOptions.useRegexp ? ".*" : "*";
  }

  List<Widget> _buildResearchOptions(String currentInput) {
    final wildcard = _getWildcardSequence();
    List<Widget> options = [];

    bool startsWithWildcard = currentInput.startsWith(wildcard);
    bool endsWithWildcard = currentInput.endsWith(wildcard);

    String coreText = currentInput;
    if (startsWithWildcard) coreText = coreText.substring(wildcard.length);
    if (endsWithWildcard) {
      coreText = coreText.substring(0, coreText.length - wildcard.length);
    }

    if (coreText.isEmpty) return options;

    if (!startsWithWildcard) {
      final newInput =
      endsWithWildcard ? '$wildcard$coreText' : '$wildcard$currentInput';
      options.add(_buildResearchButton(
        icon: Icons.keyboard_arrow_left,
        label: 'Starts with',
        newInput: newInput,
        color: Theme.of(context).colorScheme.secondaryContainer,
        foreground: Theme.of(context).colorScheme.onSecondaryContainer,
      ));
    }

    if (!endsWithWildcard) {
      final newInput =
      startsWithWildcard ? '$coreText$wildcard' : '$currentInput$wildcard';
      options.add(_buildResearchButton(
        icon: Icons.keyboard_arrow_right,
        label: 'Ends with',
        newInput: newInput,
        color: Theme.of(context).colorScheme.secondaryContainer,
        foreground: Theme.of(context).colorScheme.onSecondaryContainer,
      ));
    }

    if (!startsWithWildcard || !endsWithWildcard) {
      options.add(_buildResearchButton(
        icon: Icons.search,
        label: 'Contains',
        newInput: '$wildcard$coreText$wildcard',
        color: Theme.of(context).colorScheme.tertiaryContainer,
        foreground: Theme.of(context).colorScheme.onTertiaryContainer,
      ));
    }

    return options;
  }

  Widget _buildResearchButton({
    required IconData icon,
    required String label,
    required String newInput,
    required Color color,
    required Color foreground,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ElevatedButton.icon(
        onPressed: () {
          if (widget.textEditingController != null) {
            widget.textEditingController!.text = newInput;
          }
          widget.onSearch?.call();
        },
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
        ),
      ),
    );
  }

  Widget _buildItem(Entry item) {
    if (item is KanjiEntry) {
      return KanjiListTile(
        kanji: item.kanji,
        selected: false,
        onTap: () =>
            Clipboard.setData(ClipboardData(text: item.kanji.literal)),
      );
    }
    return ResultExpressionList(searchResult: item as ExpressionEntry);
  }

  Widget _buildResultsList(Search search) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth > 700
            ? (constraints.maxWidth / 420).floor().clamp(2, 4)
            : 1;

        final results = search.searchResults;

        if (columnCount == 1) {
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.all(8.0),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _buildItem(results[index]),
          );
        }

        return AlignedGridView.count(
          controller: _scrollController,
          padding: const EdgeInsets.all(12.0),
          crossAxisCount: columnCount,
          mainAxisSpacing: 10.0,
          crossAxisSpacing: 10.0,
          itemCount: results.length,
          itemBuilder: (context, index) => _buildItem(results[index]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocBuilder<SearchCubit, Search>(
      builder: (context, search) {
        late Widget child;

        if (search.isLoading && !search.isLoadingNextPage) {
          child = const CircularProgressIndicator();
        } else {
          final currentInput = search.searchInput;

          if (search.searchResults.isEmpty && currentInput.isNotEmpty) {
            final researchOptions = _buildResearchOptions(currentInput);
            final searchOptions = context.read<SearchOptionsCubit>().state;
            final isKanjiSearch = searchOptions.searchType == SearchType.kanji;

            child = Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  isKanjiSearch ? 'No kanji found' : 'No expressions found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "for '$currentInput'",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (researchOptions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Try searching with:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: researchOptions,
                  ),
                ],
              ],
            );
          } else if (currentInput.isEmpty) {
            child = Center(child: DatabaseStatusDisplay());
          } else {
            child = _buildResultsList(search);
          }
        }

        return Center(child: child);
      },
    );
  }
}