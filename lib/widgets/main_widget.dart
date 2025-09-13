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

class _MainWidgetState extends State<MainWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int cursorPosition = -1;
  FocusNode focusNode = FocusNode();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  initState() {
    super.initState();

    context.read<InputCubit>().addInput();
    initDb();
    loadSearchOptions();

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

  void onSearch() async {
    if (widget._textEditingController.text != "") {
      final searchOptions = context.read<SearchOptionsCubit>().state;
      final kanjiCubit = context.read<KanjiCubit>();

      final formattedInput = await formatInput(
        widget._textEditingController.text,
        kanjiCubit.databaseInterface,
      );

      // Check if the widget is still mounted before using context
      if (!mounted) return;

      context.read<InputCubit>().setFormattedInput(formattedInput);
      context.read<SearchCubit>().reset();

      // Use search type from SearchOptionsCubit
      final searchType = searchOptions.searchType;
      final databaseInterface = searchType == SearchType.kanji
          ? context.read<KanjiCubit>().databaseInterface
          : context.read<ExpressionCubit>().databaseInterface;

      // Use results per page from SearchOptionsCubit
      final resultsPerPage = searchType == SearchType.kanji
          ? searchOptions.resultsPerPageKanji
          : searchOptions.resultsPerPageExpression;

      context.read<SearchCubit>().runSearch(
        databaseInterface,
        formattedInput,
        resultsPerPage,
        searchOptions.useRegexp,
      );
    }

    focusNode.unfocus();
  }

  void onFocusChanged(bool hasFocus) async {
    setState(() {
      cursorPosition = widget._textEditingController.selection.start;
    });
  }

  void onEndReached() {
    final searchState = context.read<SearchCubit>().state;

    // Only proceed if we have more results and aren't already loading
    if (!searchState.hasMoreResults || searchState.isLoadingNextPage) {
      return;
    }

    final searchOptions = context.read<SearchOptionsCubit>().state;
    final searchType = searchOptions.searchType;

    context.read<SearchCubit>().nextPage();

    final databaseInterface = searchType == SearchType.kanji
        ? context.read<KanjiCubit>().databaseInterface
        : context.read<ExpressionCubit>().databaseInterface;

    // Use results per page from SearchOptionsCubit
    final resultsPerPage = searchType == SearchType.kanji
        ? searchOptions.resultsPerPageKanji
        : searchOptions.resultsPerPageExpression;

    context.read<SearchCubit>().runSearch(
      databaseInterface,
      context.read<InputCubit>().state.formattedInput,
      resultsPerPage,
      searchOptions.useRegexp,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ExpressionCubit, ExpressionState>(
      builder: (context, expressionState) {
        return BlocBuilder<KanjiCubit, KanjiState>(
          builder: (context, kanjiState) {
            return BlocBuilder<SearchCubit, Search>(
              builder: (context, search) {
                return BlocListener<SearchOptionsCubit, SearchOptionsState>(
                  listener: (context, searchOptionsState) {
                    saveSearchOptions(searchOptionsState);
                  },
                  child: Scaffold(
                    key: _scaffoldKey,
                    floatingActionButton:
                        context.read<SearchCubit>().state.isLoadingNextPage
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
                          textEditingController: widget._textEditingController,
                          onSearch: onSearch,
                          focusNode: focusNode,
                          insertPosition: cursorPosition,
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
                        ResultsWidget(onEndReached),
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
  }
}
