import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:fujiten/models/search.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../cubits/theme_cubit.dart';
import '../services/database_interface.dart';
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
  late DatabaseInterfaceKanji databaseInterfaceKanji;
  late DatabaseInterfaceExpression databaseInterfaceExpression;
  int cursorPosition = -1;
  FocusNode focusNode = FocusNode();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  initState() {
    super.initState();

    context.read<SearchCubit>().addInput();

    databaseInterfaceExpression = DatabaseInterfaceExpression();
    databaseInterfaceKanji = DatabaseInterfaceKanji();
    initDb().then((_){
      checkDb();
    });

    _prefs.then((SharedPreferences prefs) async {
      bool? isLight = prefs.getBool("darkTheme");
      if (isLight == true) {
        context.read<ThemeCubit>().updateTheme(ThemeData(brightness: Brightness.dark));
      }
    });
  }

  initDb() async {
    _prefs.then((SharedPreferences prefs) async {
      String? path = prefs.getString("expression_path");
      if (path != null) {
        await setExpressionDb(path);
      }
    });

    _prefs.then((SharedPreferences prefs) async {
      String? path = prefs.getString("kanji_path");
      if (path != null) {
        await setKanjiDb(path);
      }
    });
  }

  checkDb() async {
    _prefs.then((SharedPreferences prefs) async {
      String? path = prefs.getString("kanji_path");
      setState(() {
        if (path != null) {
          databaseInterfaceKanji.count().then((count) async {
            if (count == 0) {
              databaseInterfaceKanji.status = DatabaseStatus.noResults;
            } else {
              databaseInterfaceKanji.status = DatabaseStatus.ok;
            }
          });
        } else {
          databaseInterfaceKanji.status = DatabaseStatus.pathNotSet;
        }
      });
    });

    _prefs.then((SharedPreferences prefs) async {
      String? path = prefs.getString("expression_path");
      setState(() {
        if (path != null) {
          databaseInterfaceExpression.count().then((count) async {
            if (count == 0) {
              databaseInterfaceExpression.status = DatabaseStatus.noResults;
            } else {
              databaseInterfaceExpression.status = DatabaseStatus.ok;
            }
          });
        } else {
          databaseInterfaceExpression.status = DatabaseStatus.pathNotSet;
        }
      });
    });
  }

  Future<void> setExpressionDb(String path) async => await databaseInterfaceExpression.open(path);

  Future<void> setKanjiDb(String path) async => databaseInterfaceKanji.open(path);

  @override
  void dispose() {
    databaseInterfaceExpression.dispose();
    databaseInterfaceKanji.dispose();
    super.dispose();
  }

  onSearch() {
    if (widget._textEditingController.text != "") {
      formatInput(widget._textEditingController.text, databaseInterfaceKanji)
          .then((formattedInput) {
        context.read<SearchCubit>().reset();
        context.read<SearchCubit>().setFormattedInput(formattedInput);
        context.read<SearchCubit>().runSearch(
            context.read<SearchCubit>().state.searchType == SearchType.kanji
                ? databaseInterfaceKanji
                : databaseInterfaceExpression);
      });
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, Search>(
        builder: (context, search) => Scaffold(
            key: _scaffoldKey,
            floatingActionButton: context.read<SearchCubit>().state.isLoadingNextPage
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
                    checkDb: checkDb,
                    setExpressionDb: setExpressionDb,
                    setKanjiDb: setKanjiDb,
                    databaseInterfaceKanji: databaseInterfaceKanji,
                    search: search,
                    textEditingController: widget._textEditingController,
                    onSearch: onSearch,
                    focusNode: focusNode,
                    insertPosition: cursorPosition),
              ),
            ),
            body: Column(
              children: <Widget>[
                SearchInput(widget._textEditingController, onSearch, onFocusChanged, focusNode),
                if (databaseInterfaceKanji.status != DatabaseStatus.ok ||
                    databaseInterfaceExpression.status != DatabaseStatus.ok)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Kanji DB: ${databaseInterfaceKanji.status.toString()}\n Expression DB: ${databaseInterfaceExpression.status.toString()}",
                          style: const TextStyle(color: Colors.red, fontSize: 18),
                        ),
                      ],
                    ),
                  )
                else
                  ResultsWidget(
                      databaseInterfaceKanji,
                      onEndReached,
                      context.read<SearchCubit>().state.isLoading,
                      context.read<SearchCubit>().state.isLoadingNextPage)
              ],
            )));
  }
}
