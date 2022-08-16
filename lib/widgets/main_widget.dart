import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models/search.dart';
import '../services/queries.dart';
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
  Database? _dbKanji;
  Database? _dbExpression;
  final Search _search = Search(totalResult: 0, input: '');
  int? _resultsPerPage;
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isLoadingNextPage = false;
  int _cursorPosition = -1;
  bool? _kanjiSearch;
  FocusNode focusNode = FocusNode();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  _initDb() async {
    _prefs.then((SharedPreferences prefs) async {
      String? path = prefs.getString("expression_path");
      if (path != null) await setExpressionDb(path);
    });

    _prefs.then((SharedPreferences prefs) async {
      String? path = prefs.getString("kanji_path");
      if (path != null) await setKanjiDb(path);
    });
  }

  Future<void> setExpressionDb(String path) async =>
      _dbExpression = await openDatabase(path, readOnly: true);

  Future<void> setKanjiDb(String path) async => _dbKanji = await openDatabase(path, readOnly: true);

  _disposeDb() async {
    await _dbExpression!.close();
    await _dbKanji!.close();
  }

  @override
  initState() {
    _initDb();
    _resultsPerPage = 20;
    _currentPage = 0;
    _isLoading = false;
    _kanjiSearch = false;

    super.initState();
  }

  @override
  void dispose() {
    _disposeDb();
    super.dispose();
  }

  _runSearch(String input) {
    if (_kanjiSearch!) {
      searchKanji(_dbKanji!, input).then((searchResult) => setState(() {
            setState(() {
              if (searchResult.isNotEmpty) {
                _search.searchResults.addAll(searchResult);
              }
              _isLoading = false;
              _isLoadingNextPage = false;
            });
          }));
    } else {
      try {
        searchExpression(_dbExpression!, input, _resultsPerPage, _currentPage).then((searchResult) {
          setState(() {
            if (searchResult.isNotEmpty) {
              _search.searchResults.addAll(searchResult);
            }
            _isLoading = false;
            _isLoadingNextPage = false;
          });
        });
      } catch (e) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("ERROR"),
            content: Text(e.toString()),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  child: const Text("okay"),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  _searchTypeToggle() async {
    setState(() {
      _kanjiSearch = !_kanjiSearch!;
    });
  }

  _convert() async {
    String input = widget._textEditingController.text;
    if (kanaKit.isRomaji(input)) {
      widget._textEditingController.text = kanaKit.toKana(input);
    } else {
      widget._textEditingController.text = kanaKit.toRomaji(input);
    }
  }

  _onSearch() async {
    String input = await _formatInput();

    if (input.isNotEmpty) {
      setState(() {
        _isLoading = true;
        _isLoadingNextPage = false;
        _currentPage = 0;
        _search.totalResult = 0;
        _search.input = input;
        _search.searchResults.clear();
      });
      _runSearch(input);
    }
  }

  void _onFocusChanged(bool hasFocus) async {
    setState(() {
      _cursorPosition = widget._textEditingController.selection.start;
    });
  }

  _onEndReached() {
    setState(() {
      _currentPage++;
      _isLoadingNextPage = true;
    });
    _runSearch(_search.input);
  }

  Widget _body() {
    return FutureBuilder<bool>(
      future: checkDb(_dbExpression, _dbKanji), // async work
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return Column(
            children: <Widget>[
              SearchInput(widget._textEditingController, _onSearch, _onFocusChanged, focusNode),
              ResultsWidget(_dbKanji, _search, _onEndReached, _isLoading)
            ],
          );
        } else {
          return const Text("Checking DataBases integrity");
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        floatingActionButton: _isLoadingNextPage
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
                dbKanji: _dbKanji,
                search: _search,
                textEditingController: widget._textEditingController,
                onSearch: _onSearch,
                focusNode: focusNode,
                convertButton: ConvertButton(
                  onPressed: _convert,
                ),
                kanjiKotobaButton:
                    KanjiKotobaButton(onPressed: _searchTypeToggle, kanjiSearch: _kanjiSearch),
                insertPosition: _cursorPosition),
          ),
        ),
        body: _body());
  }

  Future<String> _formatInput() async {
    String input = widget._textEditingController.text.trim();
    input.replaceAll(RegExp(r'\s+'), ' ');

    //replace every radicals into < > with matching kanji in [ ] for regexp
    List<String> kanjis = [];
    var exp = RegExp(r'<(.*?)>');
    Iterable<RegExpMatch> matches = exp.allMatches(input);

    if (matches.isNotEmpty) {
      List<String?> radicalList = await getRadicalsCharacter(_dbKanji!);
      String radicalsString = radicalList.join();

      await Future.forEach(matches, (dynamic match) async {
        String radicals = match[1];
        //remove all characters that are not a radical
        radicals = radicals.replaceAll(RegExp('[^$radicalsString]'), '');

        kanjis.add(await getKanjiFromRadicals(_dbKanji!, radicals));
      });

      int index = 0;
      input = input.replaceAllMapped(exp, (Match m) {
        if (kanjis[index] == '') return m.group(0)!;
        return '[${kanjis[index++]}]';
      });
    }

    //replace regexp japanese character to latin character
    input = input.replaceAll('。', '.');
    input = input.replaceAll('？', '?');
    input = input.replaceAll('｛', '{');
    input = input.replaceAll('｝', '}');
    input = input.replaceAll('（', '(');
    input = input.replaceAll('）', ')');
    input = input.replaceAll('［', '[');
    input = input.replaceAll('］', ']');

    input = input.replaceAll(charKanji, regexKanji);
    input = input.replaceAll(charKanjiJp, regexKanji);
    input = input.replaceAll(charKana, regexKana);
    input = input.replaceAll(charKanaJp, regexKana);

    return input;
  }
}
