import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:japanese_dictionary/cubits/search_cubit.dart';
import 'package:japanese_dictionary/models/search.dart';
import 'package:japanese_dictionary/widgets/toggle_search_type_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../services/database_interface_expression.dart';
import '../services/database_interface_kanji.dart';
import '../string_utils.dart';
import 'menu_bar.dart';
import 'results_widget.dart';
import 'search_input.dart';

class MainWidget extends StatefulWidget {
  final String? title;
  final TextEditingController _textEditingController = TextEditingController();

  MainWidget({Key? key, this.title}) : super(key: key);

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Database? dbKanji;
  Database? dbExpression;
  late DatabaseInterfaceKanji databaseInterfaceKanji;
  late DatabaseInterfaceExpression databaseInterfaceExpression;
  int cursorPosition = -1;
  FocusNode focusNode = FocusNode();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  initState() {
    initDb();
    super.initState();
    databaseInterfaceExpression = DatabaseInterfaceExpression(database: dbExpression);
    databaseInterfaceKanji = DatabaseInterfaceKanji(database: dbKanji);
  }

  initDb() async {
    _prefs.then((SharedPreferences prefs) async {
      String? path = prefs.getString("expression_path");
      if (path != null) await setExpressionDb(path);
    });

    _prefs.then((SharedPreferences prefs) async {
      String? path = prefs.getString("kanji_path");
      if (path != null) await setKanjiDb(path);
    });
  }

  Future<void> setExpressionDb(String path) async {
    dbExpression = await openDatabase(path, readOnly: true);
    databaseInterfaceExpression.database = dbExpression;
  }

  Future<void> setKanjiDb(String path) async {
    dbKanji = await openDatabase(path, readOnly: true);
    databaseInterfaceKanji.database = dbKanji;
  }

  disposeDb() async {
    await dbExpression!.close();
    await dbKanji!.close();
  }

  @override
  void dispose() {
    disposeDb();
    super.dispose();
  }

  convert() async {
    String input = widget._textEditingController.text;
    if (kanaKit.isRomaji(input)) {
      widget._textEditingController.text = kanaKit.toKana(input);
    } else {
      widget._textEditingController.text = kanaKit.toRomaji(input);
    }
  }

  onSearch() => formatInput(widget._textEditingController.text, databaseInterfaceKanji)
          .then((formattedInput) {
        context.read<SearchCubit>().reset();
        log(context.read<SearchCubit>().state.searchType.toString());
        context.read<SearchCubit>().setInput(formattedInput);
        context.read<SearchCubit>().runSearch(
            context.read<SearchCubit>().state.searchType == SearchType.kanji
                ? databaseInterfaceKanji
                : databaseInterfaceExpression);
      });

  void onFocusChanged(bool hasFocus) async {
    setState(() {
      cursorPosition = widget._textEditingController.selection.start;
    });
  }

  onEndReached() {
    var searchType = context.read<SearchCubit>().state.searchType;
    context.read<SearchCubit>().nextPage();
    context.read<SearchCubit>().runSearch(
        searchType == SearchType.kanji ? databaseInterfaceKanji : databaseInterfaceExpression);
  }

  Widget body() {
    return Column(
      children: <Widget>[
        SearchInput(widget._textEditingController, onSearch, onFocusChanged, focusNode),
        ResultsWidget(
            databaseInterfaceKanji,
            onEndReached,
            context.read<SearchCubit>().state.isLoading,
            context.read<SearchCubit>().state.isLoadingNextPage)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        floatingActionButton: context.read<SearchCubit>().state.isLoadingNextPage //TODO blocBuilder
            ? const FloatingActionButton(
                onPressed: null,
                backgroundColor: Colors.white,
                mini: true,
                child: SizedBox(height: 10, width: 10, child: CircularProgressIndicator()),
              )
            : null,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Builder(
            builder: (context) => MenuBar(
                setExpressionDb: setExpressionDb,
                setKanjiDb: setKanjiDb,
                databaseInterfaceKanji: databaseInterfaceKanji,
                search: context.read<SearchCubit>().state,
                textEditingController: widget._textEditingController,
                onSearch: onSearch,
                focusNode: focusNode,
                convertButton: ConvertButton(
                  onPressed: convert,
                ),
                kanjiKotobaButton: const ToggleSearchTypeButton(),
                insertPosition: cursorPosition),
          ),
        ),
        body: body());
  }
}
