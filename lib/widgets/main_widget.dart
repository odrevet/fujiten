import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../services/queries.dart';
import '../models/search.dart';
import 'search_input.dart';
import '../string_utils.dart';
import 'menu_bar.dart';
import 'results_widget.dart';

class MainWidget extends StatefulWidget {
  final String? title;
  final TextEditingController _textEditingController = TextEditingController();

  MainWidget({Key? key, this.title}) : super(key: key);

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  Database? _dbKanji;
  late Database _dbExpression;

  Search? _search;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int? _resultsPerPage;
  int _currentPage = 0;
  bool? _isLoading;
  int _cursorPosition = -1;
  bool? _kanjiSearch;
  late String _lang;

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
    await _dbExpression.close();
    await _dbKanji!.close();
  }

  @override
  initState() {
    _initDb();
    _search = Search(totalResult: 0, input: '');
    _resultsPerPage = 20;
    _currentPage = 0;
    _isLoading = false;
    _kanjiSearch = false;
    _lang = 'eng';

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
                _search!.searchResults.addAll(searchResult);
              }
              _isLoading = false;
            });
          }));
    } else {
      searchExpression(_dbExpression, input, _lang, _resultsPerPage, _currentPage)
          .then((searchResult) {
        setState(() {
          if (searchResult.isNotEmpty) {
            _search!.searchResults.addAll(searchResult);
          }
          _isLoading = false;
        });
      });
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
      widget._textEditingController.text = kanaKit.toHiragana(input);
    } else {
      widget._textEditingController.text = kanaKit.toKana(input);
    }
  }

  _onSearch() async {
    String input = await _formatInput();

    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _search!.totalResult = 0;
      _search!.input = input;
      _search!.searchResults.clear();
    });

    _runSearch(input);
  }

  _onLanguageSelect(String? lang) => setState(() {
        _lang = lang!;
      });

  void _onFocusChanged(bool hasFocus) async {
    setState(() {
      _cursorPosition = widget._textEditingController.selection.start;
    });
  }

  _onEndReached() {
    setState(() {
      _currentPage++;
    });
    _runSearch(_search!.input);
  }

  Widget _body() {
    return Column(
      children: <Widget>[
        SearchInput(widget._textEditingController, _onSearch, _onFocusChanged),
        ResultsWidget(_dbKanji, _search, _onEndReached, _isLoading)
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
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
                onLanguageSelect: _onLanguageSelect,
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
    //remove space characters
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
    input = input.replaceAll(charKanji, regexKanji);
    input = input.replaceAll(charKana, regexKana);

    return input;
  }
}
