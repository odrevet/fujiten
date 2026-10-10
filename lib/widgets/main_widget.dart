import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/config.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:fujiten/models/search.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cubits/expression_cubit.dart';
import '../cubits/input_cubit.dart';
import '../cubits/kanji_cubit.dart';
import '../cubits/search_options_cubit.dart';
import '../models/input.dart';
import '../models/states/db_state_expression.dart';
import '../models/states/db_state_kanji.dart';
import '../models/states/search_options_state.dart';
import '../services/database_interface.dart';
import '../string_utils.dart';
import 'fujiten_menu_bar.dart';
import 'results_widget.dart';
import 'search_input.dart';
import 'settings/settings.dart';

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

    initDb();
    loadSearchOptions();
    loadSessions();

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

    // Listen for shared text from Android intents
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSharedTextHandler();
    });

    // Listen to tab changes and update search type
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) return;

      final newSearchType = _tabController.index == 0
          ? SearchType.expression
          : SearchType.kanji;
      context.read<SearchOptionsCubit>().setSearchType(newSearchType);
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

    // On web only the Postgres backend is available.
    final isWeb = kIsWeb;

    // Initialize expression database
    final expressionBackend = isWeb
        ? 'postgres'
        : prefs.getString("expression_backend") ?? 'sqlite';
    if (expressionBackend == 'postgres') {
      final url = prefs.getString("postgres_url") ?? SupabaseConfig.url;
      final anonKey =
          prefs.getString("postgres_anon_key") ?? SupabaseConfig.anonKey;
      if (url.isNotEmpty && anonKey.isNotEmpty && mounted) {
        context.read<ExpressionCubit>().configure(
          DatabaseBackend.postgres,
          url: url,
          anonKey: anonKey,
        );
      }
    } else {
      String? expressionPath = prefs.getString("expression_path");
      if (expressionPath != null && mounted) {
        context.read<ExpressionCubit>().openDatabase(expressionPath);
      }
    }

    // Initialize kanji database
    final kanjiBackend = isWeb
        ? 'postgres'
        : prefs.getString("kanji_backend") ?? 'sqlite';
    if (kanjiBackend == 'postgres') {
      final url = prefs.getString("postgres_url") ?? SupabaseConfig.url;
      final anonKey =
          prefs.getString("postgres_anon_key") ?? SupabaseConfig.anonKey;
      if (url.isNotEmpty && anonKey.isNotEmpty && mounted) {
        context.read<KanjiCubit>().configure(
          DatabaseBackend.postgres,
          url: url,
          anonKey: anonKey,
        );
      }
    } else {
      String? kanjiPath = prefs.getString("kanji_path");
      if (kanjiPath != null && mounted) {
        context.read<KanjiCubit>().openDatabase(kanjiPath);
      }
    }
  }

  void loadSearchOptions() async {
    final prefs = await _prefs;
    if (!mounted) return;

    // Load search options from SharedPreferences
    SearchMode readMode(String key, SearchMode fallback) {
      final name = prefs.getString(key);
      if (name != null) {
        return SearchMode.values.firstWhere(
          (m) => m.name == name,
          orElse: () => fallback,
        );
      }
      return fallback;
    }

    // Migrate the old single regexp toggle if the new keys are absent.
    final hasExpressionMode = prefs.containsKey("search_mode_expression");
    final hasKanjiMode = prefs.containsKey("search_mode_kanji");
    final oldUseRegexp = prefs.getBool("search_use_regexp");

    // Default to regexp when the backend supports it, otherwise glob.
    final isWeb = kIsWeb;
    final expressionBackend = isWeb
        ? 'postgres'
        : prefs.getString("expression_backend") ?? 'sqlite';
    final kanjiBackend = isWeb
        ? 'postgres'
        : prefs.getString("kanji_backend") ?? 'sqlite';
    SearchMode backendDefault(String backend) =>
        backend == 'postgres' ? SearchMode.regexp : SearchMode.glob;

    final expressionSearchMode = hasExpressionMode
        ? readMode("search_mode_expression", SearchMode.regexp)
        : (oldUseRegexp == true
              ? SearchMode.regexp
              : (oldUseRegexp == false
                    ? SearchMode.glob
                    : backendDefault(expressionBackend)));
    final kanjiSearchMode = hasKanjiMode
        ? readMode("search_mode_kanji", SearchMode.regexp)
        : (oldUseRegexp == true
              ? SearchMode.regexp
              : (oldUseRegexp == false
                    ? SearchMode.glob
                    : backendDefault(kanjiBackend)));

    final resultsPerPageKanji =
        prefs.getInt("search_results_per_page_kanji") ?? 20;
    final resultsPerPageExpression =
        prefs.getInt("search_results_per_page_expression") ?? 20;
    final searchTypeIndex = prefs.getInt("search_type") ?? 0;
    final searchType = searchTypeIndex == 0
        ? SearchType.expression
        : SearchType.kanji;
    final selectedLangsExpression =
        prefs.getStringList("search_langs_expression") ?? [];
    final selectedLangsKanji =
        prefs.getStringList("search_langs_kanji") ?? [];

    context.read<SearchOptionsCubit>().updateSearchOptions(
      expressionSearchMode: expressionSearchMode,
      kanjiSearchMode: kanjiSearchMode,
      resultsPerPageKanji: resultsPerPageKanji,
      resultsPerPageExpression: resultsPerPageExpression,
      searchType: searchType,
      selectedLangsExpression: selectedLangsExpression,
      selectedLangsKanji: selectedLangsKanji,
    );

    // Update tab controller to match loaded search type
    if (mounted) {
      _tabController.animateTo(searchType == SearchType.expression ? 0 : 1);
    }
  }

  void saveSearchOptions(SearchOptionsState searchOptions) async {
    final prefs = await _prefs;

    // Save search options to SharedPreferences
    await prefs.setString(
      "search_mode_expression",
      searchOptions.expressionSearchMode.name,
    );
    await prefs.setString(
      "search_mode_kanji",
      searchOptions.kanjiSearchMode.name,
    );
    await prefs.setInt(
      "search_results_per_page_kanji",
      searchOptions.resultsPerPageKanji,
    );
    await prefs.setInt(
      "search_results_per_page_expression",
      searchOptions.resultsPerPageExpression,
    );
    await prefs.setInt("search_type", searchOptions.searchType.index);
    await prefs.setStringList(
      "search_langs_expression",
      searchOptions.selectedLangsExpression,
    );
    await prefs.setStringList(
      "search_langs_kanji",
      searchOptions.selectedLangsKanji,
    );
  }

  void loadSessions() async {
    final prefs = await _prefs;
    if (!mounted) return;

    final sessionsJson = prefs.getString("search_sessions");
    final sessions = _parseSessions(sessionsJson);

    var searchIndex = prefs.getInt("search_index") ?? 0;
    if (searchIndex < 0 || searchIndex >= sessions.length) {
      searchIndex = 0;
    }

    context.read<InputCubit>().loadSessions(sessions, searchIndex);
    widget._textEditingController.text = sessions[searchIndex].currentInput;
  }

  List<SearchSession> _parseSessions(String? json) {
    if (json == null || json.isEmpty) return [SearchSession()];
    try {
      return (jsonDecode(json) as List)
          .map((e) => SearchSession.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [SearchSession()];
    }
  }

  void saveSessions(Input input) async {
    final prefs = await _prefs;
    await prefs.setString(
      "search_sessions",
      jsonEncode(input.sessions.map((s) => s.toJson()).toList()),
    );
    await prefs.setInt("search_index", input.searchIndex);
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
      context
          .read<InputCubit>()
          .recordSearch(widget._textEditingController.text);

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

    final langs = searchType == SearchType.kanji
        ? searchOptions.selectedLangsKanji
        : searchOptions.selectedLangsExpression;

    final mode = searchType == SearchType.kanji
        ? searchOptions.kanjiSearchMode
        : searchOptions.expressionSearchMode;

    searchCubit.runSearch(
      databaseInterface,
      formattedInput,
      resultsPerPage,
      mode,
      langs,
    );
  }

  Future<void> _setupSharedTextHandler() async {
    // Shared text from intents is only available on mobile platforms.
    if (kIsWeb) return;

    const platform = MethodChannel('app.fujiten/shared_text');

    platform.setMethodCallHandler((call) async {
      if (call.method == 'onSharedText') {
        final text = call.arguments as String?;
        if (text != null && mounted) {
          _handleSharedText(text);
        }
      }
    });

    try {
      final initialText = await platform.invokeMethod<String>('getSharedText');
      if (initialText != null && initialText.isNotEmpty && mounted) {
        _handleSharedText(initialText);
      }
    } catch (_) {
      // Method channel not available on this platform.
    }
  }

  void _handleSharedText(String text) {
    widget._textEditingController.text = text;
    onSearch();
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

    final langs = searchOptions.searchType == SearchType.kanji
        ? searchOptions.selectedLangsKanji
        : searchOptions.selectedLangsExpression;

    final mode = searchOptions.searchType == SearchType.kanji
        ? searchOptions.kanjiSearchMode
        : searchOptions.expressionSearchMode;

    searchCubit.runSearch(
      databaseInterface,
      context.read<InputCubit>().state.formattedInput,
      resultsPerPage,
      mode,
      langs,
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

  // Regexp/glob syntax and digits that must never be converted
  static final _protected = RegExp(r'\{\d*,?\d*\}|[.*+?^$|\\()\[\]{}\d]');

  String _convertSegments(String input, String Function(String) convert) {
    final buffer = StringBuffer();
    var last = 0;
    for (final m in _protected.allMatches(input)) {
      if (m.start > last) buffer.write(convert(input.substring(last, m.start)));
      buffer.write(m.group(0)); // keep syntax as is
      last = m.end;
    }
    if (last < input.length) buffer.write(convert(input.substring(last)));
    return buffer.toString();
  }

  void convert() {
    final input = widget._textEditingController.text;

    // Detect the current script on the text without syntax or digits
    final core = input.replaceAll(_protected, '').replaceAll(' ', '');
    if (core.isEmpty) return;

    final String Function(String) converter;
    if (kanaKit.isHiragana(core)) {
      converter = kanaKit.toKatakana;
    } else if (kanaKit.isKatakana(core)) {
      converter = kanaKit.toRomaji;
    } else {
      converter = kanaKit.toKana; // romaji (or anything else) -> hiragana
    }

    final convertedInput = _convertSegments(input, converter);

    widget._textEditingController.text = convertedInput;
    context.read<InputCubit>().setInput(convertedInput);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
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
                      child: BlocListener<InputCubit, Input>(
                        listener: (context, input) {
                          saveSessions(input);
                        },
                        child: Scaffold(
                          key: _scaffoldKey,
                          drawer: Drawer(child: SettingsPage()),
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
                              onToggleSearchType: _toggleSearchType,
                              currentSearchType: searchOptionsState.searchType,
                              onConvert: convert,
                            ),
                          ),
                        ),
                        body: Column(
                          children: <Widget>[
                            if (!isLandscape)
                              SearchInput(
                                widget._textEditingController,
                                onSearch,
                                onFocusChanged,
                                focusNode,
                                onConvert: convert,
                              ),
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
