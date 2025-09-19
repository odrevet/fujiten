import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  String _getWildcardSequence() {
    // Access searchOptionsState from context
    final searchOptions = context.read<SearchOptionsCubit>().state;
    return searchOptions.useRegexp ? ".*" : "*";
  }

  List<Widget> _buildResearchOptions(String currentInput) {
    final wildcard = _getWildcardSequence();
    List<Widget> options = [];

    // Parse current input to understand its wildcard structure
    bool startsWithWildcard = currentInput.startsWith(wildcard);
    bool endsWithWildcard = currentInput.endsWith(wildcard);

    // Get the core text without wildcards
    String coreText = currentInput;
    if (startsWithWildcard) {
      coreText = coreText.substring(wildcard.length);
    }
    if (endsWithWildcard) {
      coreText = coreText.substring(0, coreText.length - wildcard.length);
    }

    // If core text is empty after removing wildcards, don't show options
    if (coreText.isEmpty) {
      return options;
    }

    // "Starts with" option - only show if not already starts with wildcard
    if (!startsWithWildcard) {
      String newInput;
      if (endsWithWildcard) {
        // If currently ends with wildcard, remove it and add at beginning
        newInput = '$wildcard$coreText';
      } else {
        // Simple case: add wildcard at beginning
        newInput = '$wildcard$currentInput';
      }

      options.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.textEditingController != null) {
                widget.textEditingController!.text = newInput;
              }
              widget.onSearch?.call();
            },
            icon: const Icon(Icons.keyboard_arrow_left, size: 16),
            label: const Text('Starts with'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(
                context,
              ).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      );
    }

    // "Ends with" option - only show if not already ends with wildcard
    if (!endsWithWildcard) {
      String newInput;
      if (startsWithWildcard) {
        // If currently starts with wildcard, remove it and add at end
        newInput = '$coreText$wildcard';
      } else {
        // Simple case: add wildcard at end
        newInput = '$currentInput$wildcard';
      }

      options.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.textEditingController != null) {
                widget.textEditingController!.text = newInput;
              }
              widget.onSearch?.call();
            },
            icon: const Icon(Icons.keyboard_arrow_right, size: 16),
            label: const Text('Ends with'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(
                context,
              ).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      );
    }

    // "Contains" option - only show if not already both starts and ends with wildcard
    if (!startsWithWildcard || !endsWithWildcard) {
      String newInput = '$wildcard$coreText$wildcard';

      options.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.textEditingController != null) {
                widget.textEditingController!.text = newInput;
              }
              widget.onSearch?.call();
            },
            icon: const Icon(Icons.search, size: 16),
            label: const Text('Contains'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              foregroundColor: Theme.of(
                context,
              ).colorScheme.onTertiaryContainer,
            ),
          ),
        ),
      );
    }

    return options;
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
          final currentInput = search.searchInput;

          if (search.searchResults.isEmpty && currentInput.isNotEmpty) {
            final researchOptions = _buildResearchOptions(currentInput);

            // Determine search type from search options
            final searchOptions = context.read<SearchOptionsCubit>().state;
            final isKanjiSearch = searchOptions.searchType == SearchType.kanji;

            String noResultsText;
            if (isKanjiSearch) {
              noResultsText = "No kanji found";
            } else {
              noResultsText = "No expressions found";
            }

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
                  noResultsText,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "for '$currentInput'",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (researchOptions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    "Try searching with:",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
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
          } else {
            if (currentInput.isEmpty) {
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
