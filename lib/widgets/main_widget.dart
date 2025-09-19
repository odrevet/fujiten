import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:fujiten/models/search.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cubits/expression_cubit.dart';
import '../cubits/input_cubit.dart';
import '../cubits/kanji_cubit.dart';
import '../cubits/search_options_cubit.dart';
import '../cubits/theme_cubit.dart';
import '../models/states/db_state_expression.dart';
import '../models/states/db_state_kanji.dart';
import '../models/states/search_options_state.dart';
import '../string_utils.dart';
import 'fujiten_menu_bar.dart';
import 'results_widget.dart';
import 'search_input.dart';

class MainWidget extends StatefulWidget {
  final String? title;
  final TextEditingController _textEditingController = TextEditingController();

  MainWidget({super.key, this.title});

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int cursorPosition = -1;
  FocusNode focusNode = FocusNode();
  late TabController _tabController;

  // Separate search cubits for each tab
  late SearchCubit _expressionSearchCubit;
  late SearchCubit _kanjiSearchCubit;

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  initState() {
    super.initState();

    // Initialize separate search cubits
    _expressionSearchCubit = SearchCubit();
    _kanjiSearchCubit = SearchCubit();

    context.read<InputCubit>().addInput();
    initDb();
    loadSearchOptions();

    // Initialize tab controller
    final searchOptions = context.read<SearchOptionsCubit>().state;
    final initialIndex = searchOptions.searchType == SearchType.expression
        ? 0
        : 1;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialIndex,
    );

    // Listen to tab changes and update search type
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;

      final newSearchType = _tabController.index == 0
          ? SearchType.expression
          : SearchType.kanji;

      context.read<SearchOptionsCubit>().setSearchType(newSearchType);

      // Don't trigger search on tab change - let each tab maintain its state
    });

    _prefs.then((SharedPreferences prefs) {
      if (!mounted) return;
      bool? isLight = prefs.getBool("darkTheme");
      if (isLight == true) {
        context.read<ThemeCubit>().updateTheme(
          ThemeData(brightness: Brightness.dark),
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _expressionSearchCubit.close();
    _kanjiSearchCubit.close();
    super.dispose();
  }

  void initDb() async {
    final prefs = await _prefs;

    // Initialize expression database
    String? expressionPath = prefs.getString("expression_path");
    if (expressionPath != null && mounted) {
      context.read<ExpressionCubit>().openDatabase(expressionPath);
    }

    // Initialize kanji database
    String? kanjiPath = prefs.getString("kanji_path");
    if (kanjiPath != null && mounted) {
      context.read<KanjiCubit>().openDatabase(kanjiPath);
    }
  }

  void loadSearchOptions() async {
    final prefs = await _prefs;
    if (!mounted) return;

    // Load search options from SharedPreferences
    final useRegexp = prefs.getBool("search_use_regexp") ?? false;
    final resultsPerPageKanji =
        prefs.getInt("search_results_per_page_kanji") ?? 20;
    final resultsPerPageExpression =
        prefs.getInt("search_results_per_page_expression") ?? 20;
    final searchTypeIndex = prefs.getInt("search_type") ?? 0;
    final searchType = searchTypeIndex == 0
        ? SearchType.expression
        : SearchType.kanji;

    context.read<SearchOptionsCubit>().updateSearchOptions(
      useRegexp: useRegexp,
      resultsPerPageKanji: resultsPerPageKanji,
      resultsPerPageExpression: resultsPerPageExpression,
      searchType: searchType,
    );

    // Update tab controller to match loaded search type
    if (mounted) {
      _tabController.animateTo(searchType == SearchType.expression ? 0 : 1);
    }
  }

  void saveSearchOptions(SearchOptionsState searchOptions) async {
    final prefs = await _prefs;

    // Save search options to SharedPreferences
    await prefs.setBool("search_use_regexp", searchOptions.useRegexp);
    await prefs.setInt(
      "search_results_per_page_kanji",
      searchOptions.resultsPerPageKanji,
    );
    await prefs.setInt(
      "search_results_per_page_expression",
      searchOptions.resultsPerPageExpression,
    );
    await prefs.setInt("search_type", searchOptions.searchType.index);
  }

  // Get the appropriate search cubit based on search type
  SearchCubit _getCurrentSearchCubit(SearchType searchType) {
    return searchType == SearchType.expression
        ? _expressionSearchCubit
        : _kanjiSearchCubit;
  }

  void onSearch() async {
    if (widget._textEditingController.text != "") {
      final kanjiCubit = context.read<KanjiCubit>();

      final formattedInput = await formatInput(
        widget._textEditingController.text,
        kanjiCubit.databaseInterface,
      );

      // Check if the widget is still mounted before using context
      if (!mounted) return;

      context.read<InputCubit>().setFormattedInput(formattedInput);

      // Reset both search cubits when input changes
      _expressionSearchCubit.reset();
      _kanjiSearchCubit.reset();

      // Run search for both types to keep them in sync with new input
      await _runSearchForType(SearchType.expression, formattedInput);
      await _runSearchForType(SearchType.kanji, formattedInput);
    }

    focusNode.unfocus();
  }

  Future<void> _runSearchForType(
    SearchType searchType,
    String formattedInput,
  ) async {
    final searchOptions = context.read<SearchOptionsCubit>().state;
    final searchCubit = _getCurrentSearchCubit(searchType);

    final databaseInterface = searchType == SearchType.kanji
        ? context.read<KanjiCubit>().databaseInterface
        : context.read<ExpressionCubit>().databaseInterface;

    final resultsPerPage = searchType == SearchType.kanji
        ? searchOptions.resultsPerPageKanji
        : searchOptions.resultsPerPageExpression;

    searchCubit.runSearch(
      databaseInterface,
      formattedInput,
      resultsPerPage,
      searchOptions.useRegexp,
    );
  }

  void onFocusChanged(bool hasFocus) async {
    setState(() {
      cursorPosition = widget._textEditingController.selection.start;
    });
  }

  void onEndReached() {
    final searchOptions = context.read<SearchOptionsCubit>().state;
    final searchCubit = _getCurrentSearchCubit(searchOptions.searchType);
    final searchState = searchCubit.state;

    // Only proceed if we have more results and aren't already loading
    if (!searchState.hasMoreResults || searchState.isLoadingNextPage) {
      return;
    }

    searchCubit.nextPage();

    final databaseInterface = searchOptions.searchType == SearchType.kanji
        ? context.read<KanjiCubit>().databaseInterface
        : context.read<ExpressionCubit>().databaseInterface;

    // Use results per page from SearchOptionsCubit
    final resultsPerPage = searchOptions.searchType == SearchType.kanji
        ? searchOptions.resultsPerPageKanji
        : searchOptions.resultsPerPageExpression;

    searchCubit.runSearch(
      databaseInterface,
      context.read<InputCubit>().state.formattedInput,
      resultsPerPage,
      searchOptions.useRegexp,
    );
  }

  // Toggle between Expression and Kanji search types
  void _toggleSearchType() {
    final currentSearchType = context
        .read<SearchOptionsCubit>()
        .state
        .searchType;
    final newSearchType = currentSearchType == SearchType.expression
        ? SearchType.kanji
        : SearchType.expression;

    context.read<SearchOptionsCubit>().setSearchType(newSearchType);
    _tabController.animateTo(newSearchType == SearchType.expression ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpressionCubit, ExpressionState>(
      builder: (context, expressionState) {
        return BlocBuilder<KanjiCubit, KanjiState>(
          builder: (context, kanjiState) {
            return BlocBuilder<SearchOptionsCubit, SearchOptionsState>(
              builder: (context, searchOptionsState) {
                final currentSearchCubit = _getCurrentSearchCubit(
                  searchOptionsState.searchType,
                );

                return BlocBuilder<SearchCubit, Search>(
                  bloc: currentSearchCubit,
                  builder: (context, search) {
                    return BlocListener<SearchOptionsCubit, SearchOptionsState>(
                      listener: (context, searchOptionsState) {
                        saveSearchOptions(searchOptionsState);
                        // Update tab controller when search type changes externally
                        final newIndex =
                            searchOptionsState.searchType ==
                                SearchType.expression
                            ? 0
                            : 1;
                        if (_tabController.index != newIndex) {
                          _tabController.animateTo(newIndex);
                        }
                      },
                      child: Scaffold(
                        key: _scaffoldKey,
                        floatingActionButton: search.isLoadingNextPage
                            ? const FloatingActionButton(
                                onPressed: null,
                                backgroundColor: Colors.white,
                                mini: true,
                                child: SizedBox(
                                  height: 10,
                                  width: 10,
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : null,
                        appBar: PreferredSize(
                          preferredSize: const Size.fromHeight(56),
                          child: Builder(
                            builder: (context) => FujitenMenuBar(
                              search: search,
                              textEditingController:
                                  widget._textEditingController,
                              onSearch: onSearch,
                              focusNode: focusNode,
                              insertPosition: cursorPosition,
                              // Pass the toggle function and current search type
                              onToggleSearchType: _toggleSearchType,
                              currentSearchType: searchOptionsState.searchType,
                            ),
                          ),
                        ),
                        body: Column(
                          children: <Widget>[
                            SearchInput(
                              widget._textEditingController,
                              onSearch,
                              onFocusChanged,
                              focusNode,
                            ),
                            // Remove the TabBar - it's now in the AppBar
                            Expanded(
                              child: TabBarView(
                                physics: const NeverScrollableScrollPhysics(),
                                controller: _tabController,
                                children: [
                                  // Expression tab content
                                  BlocProvider.value(
                                    value: _expressionSearchCubit,
                                    child: ResultsWidget(
                                      onEndReached,
                                      textEditingController:
                                          widget._textEditingController,
                                      onSearch: onSearch,
                                    ),
                                  ),
                                  // Kanji tab content
                                  BlocProvider.value(
                                    value: _kanjiSearchCubit,
                                    child: ResultsWidget(
                                      onEndReached,
                                      textEditingController:
                                          widget._textEditingController,
                                      onSearch: onSearch,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
