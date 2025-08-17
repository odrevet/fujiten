import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:fujiten/models/search.dart';
import 'package:fujiten/widgets/settings/dataset_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cubits/expression_cubit.dart';
import '../cubits/input_cubit.dart';
import '../cubits/kanji_cubit.dart';
import '../cubits/theme_cubit.dart';
import '../models/db_state_expression.dart';
import '../models/db_state_kanji.dart';
import '../services/database_interface.dart';
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

  bool _isDbInitializedExpression = false;
  bool _isDbInitializedKanji = false;

  @override
  initState() {
    super.initState();

    context.read<InputCubit>().addInput();
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
      context.read<ExpressionCubit>().openDatabase(expressionPath);
    }

    // Initialize kanji database
    String? kanjiPath = prefs.getString("kanji_path");
    if (kanjiPath != null) {
      context.read<KanjiCubit>().openDatabase(kanjiPath);
    }
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
      context.read<SearchCubit>().reset();

      final searchType = context.read<SearchCubit>().state.searchType;
      final databaseInterface = searchType == SearchType.kanji
          ? context.read<KanjiCubit>().databaseInterface
          : context.read<ExpressionCubit>().databaseInterface;

      context.read<SearchCubit>().runSearch(databaseInterface, formattedInput);
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

    final databaseInterface = searchType == SearchType.kanji
        ? context.read<KanjiCubit>().databaseInterface
        : context.read<ExpressionCubit>().databaseInterface;

    context.read<SearchCubit>().runSearch(
      databaseInterface,
      context.read<InputCubit>().state.formattedInput,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ExpressionCubit, ExpressionState>(
          listener: (context, expressionState) {
            _updateDbInitializedExpression(expressionState);
          },
        ),
        BlocListener<KanjiCubit, KanjiState>(
          listener: (context, kanjiState) {
            _updateDbInitializedKanji(kanjiState);
          },
        ),
      ],
      child: BlocBuilder<SearchCubit, Search>(
        builder: (context, search) {
          //if (!_isDbInitializedExpression || !_isDbInitializedKanji) {
          //  return DatasetPage(refreshDbStatus: () {}); //WIP
          //} else {
            return Scaffold(
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
                    insertPosition: cursorPosition
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
                  ResultsWidget(
                    onEndReached
                  ),
                ],
              ),
            );
          //}
        },
      ),
    );
  }

  void _updateDbInitializedExpression(ExpressionState expressionState) {
    setState(() {
      _isDbInitializedExpression = expressionState is ExpressionLoaded;
    });
  }

  void _updateDbInitializedKanji(KanjiState kanjiState) {
    setState(() {
      _isDbInitializedKanji = KanjiState is KanjiLoaded;
    });
  }
}
