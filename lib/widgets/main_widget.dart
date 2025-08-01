import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:fujiten/models/search.dart';
import 'package:fujiten/widgets/settings/dataset_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cubits/input_cubit.dart';
import '../cubits/theme_cubit.dart';
import '../services/database_interface.dart';
import '../services/database_interface_expression.dart';
import '../services/database_interface_kanji.dart';
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
  late DatabaseInterfaceKanji databaseInterfaceKanji;
  late DatabaseInterfaceExpression databaseInterfaceExpression;
  int cursorPosition = -1;
  FocusNode focusNode = FocusNode();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  bool _isDbInitialized = false;

  @override
  initState() {
    super.initState();

    context.read<InputCubit>().addInput();

    databaseInterfaceExpression = DatabaseInterfaceExpression();
    databaseInterfaceKanji = DatabaseInterfaceKanji();

    initDb();

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
    if (expressionPath != null) {
      await setExpressionDb(expressionPath);
    }

    // Initialize kanji database
    String? kanjiPath = prefs.getString("kanji_path");
    if (kanjiPath != null) {
      await setKanjiDb(kanjiPath);
    }

    await refreshDbStatus();
  }

  Future<void> refreshDbStatus() async {
    await databaseInterfaceExpression.setStatus();
    await databaseInterfaceKanji.setStatus();
    setState(() {
      _isDbInitialized = true;
    });
  }

  Future<void> setExpressionDb(String path) async =>
      await databaseInterfaceExpression.open(path);

  Future<void> setKanjiDb(String path) async =>
      databaseInterfaceKanji.open(path);

  @override
  void dispose() {
    databaseInterfaceExpression.dispose();
    databaseInterfaceKanji.dispose();
    super.dispose();
  }

  void onSearch() async {
    if (widget._textEditingController.text != "") {
      final formattedInput = await formatInput(
        widget._textEditingController.text,
        databaseInterfaceKanji,
      );

      // Check if the widget is still mounted before using context
      if (!mounted) return;

      context.read<InputCubit>().setFormattedInput(formattedInput);
      context.read<SearchCubit>().reset();
      context.read<SearchCubit>().runSearch(
        context.read<SearchCubit>().state.searchType == SearchType.kanji
            ? databaseInterfaceKanji
            : databaseInterfaceExpression,
        formattedInput,
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
    var searchType = context.read<SearchCubit>().state.searchType;
    context.read<SearchCubit>().nextPage();
    context.read<SearchCubit>().runSearch(
      searchType == SearchType.kanji
          ? databaseInterfaceKanji
          : databaseInterfaceExpression,
      context.read<InputCubit>().state.formattedInput,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDbInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool databasesOk =
        databaseInterfaceExpression.status == DatabaseStatus.ok &&
        databaseInterfaceKanji.status == DatabaseStatus.ok;

    if (!databasesOk) {
      return DatasetPage(
        databaseInterfaceExpression: databaseInterfaceExpression,
        databaseInterfaceKanji: databaseInterfaceKanji,
        refreshDbStatus: refreshDbStatus,
      );
    } else {
      return BlocBuilder<SearchCubit, Search>(
        builder: (context, search) => Scaffold(
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
          appBar: databasesOk
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Builder(
                    builder: (context) => FujitenMenuBar(
                      databaseInterfaceKanji: databaseInterfaceKanji,
                      databaseInterfaceExpression: databaseInterfaceExpression,
                      search: search,
                      textEditingController: widget._textEditingController,
                      onSearch: onSearch,
                      focusNode: focusNode,
                      insertPosition: cursorPosition,
                      refreshDbStatus: refreshDbStatus,
                    ),
                  ),
                )
              : null,
          body: Column(
            children: <Widget>[
              if (databasesOk)
                SearchInput(
                  widget._textEditingController,
                  onSearch,
                  onFocusChanged,
                  focusNode,
                ),
              ResultsWidget(
                databaseInterfaceKanji,
                databaseInterfaceExpression,
                onEndReached,
                refreshDbStatus,
              ),
            ],
          ),
        ),
      );
    }
  }
}
