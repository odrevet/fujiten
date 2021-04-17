import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'db.dart';
import 'menuBar.dart';
import 'queries.dart';
import 'resultsWidget.dart';
import 'search.dart';
import 'searchInput.dart';
import 'stringUtils.dart';

class MainWidget extends StatefulWidget {
  final String title;
  final TextEditingController _textEditingController = TextEditingController();

  MainWidget({Key key, this.title}) : super(key: key);

  @override
  _MainWidgetState createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  Database _dbKanji;
  Database _dbExpression;

  Search _search;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _resultsPerPage;
  int _currentPage;
  bool _isLoading;
  int _cursorPosition = -1;
  bool _kanjiSearch;
  String _lang;

  _initDb() async {
    await installDb('kanji.db');
    await installDb('expression.db');

    _dbKanji = await openDb('kanji.db');
    _dbExpression = await openDb('expression.db');
  }

  _disposeDb() async {
    await _dbExpression.close();
    await _dbKanji.close();
  }

  @override
  initState() {
    _initDb();
    _search = Search(totalResult: 0);
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

/*
  _displaySnackBar(String message) {
    _scaffoldKey.currentState.showSnackBar(SnackBar(
      content: Text(message),
    ));
  }

  String _formatSnackBarMessage() {
    String searchType = 
    KotobaButton.kanjiSearch ? 'kanji' : 'expression';

    if (_search.totalResult == 0) {
      return 'No match found';
    }

    if (_search.totalResult > 1) searchType += 's';

    int resultsCount = _resultsPerPage > _search.totalResult
        ? _search.totalResult
        : _resultsPerPage;
    return '$resultsCount of ${_search.totalResult} $searchType';
  }*/

  _runSearch(String input) {
    if (_kanjiSearch) {
      searchKanji(_dbKanji, input).then((searchResult) => setState(() {
            setState(() {
              if (searchResult.isNotEmpty)
                _search.searchResults.addAll(searchResult);
              _isLoading = false;
              //_displaySnackBar(_formatSnackBarMessage());
            });
            //_displaySnackBar(_formatSnackBarMessage());
          }));
    } else {
      searchExpression(
              _dbExpression, input, _lang, _resultsPerPage, _currentPage)
          .then((searchResult) {
        setState(() {
          if (searchResult.isNotEmpty)
            _search.searchResults.addAll(searchResult);
          _isLoading = false;
          //_displaySnackBar(_formatSnackBarMessage());
        });
      });
    }
  }

  _searchTypeToggle() async {
    setState(() {
      _kanjiSearch = !_kanjiSearch;
    });
  }

  _onSearch() async {
    String input = await _formatInput();

    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _search.totalResult = 0;
      _search.input = input;
      _search.searchResults.clear();
    });

    _runSearch(input);
  }

  _onLanguageSelect(String lang) => setState(() {
        _lang = lang;
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
    _runSearch(_search.input);
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
          preferredSize: Size.fromHeight(56),
          child: Builder(
            builder: (context) => MenuBar(
                dbKanji: _dbKanji,
                search: _search,
                textEditingController: widget._textEditingController,
                onSearch: _onSearch,
                onLanguageSelect: _onLanguageSelect,
                kanjiKotobaButton: KanjiKotobaButton(
                    onPressed: _searchTypeToggle, kanjiSearch: _kanjiSearch),
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

    List<String> radicalList = await getRadicalsCharacter(_dbKanji);
    String radicalsString = radicalList.join();

    await Future.forEach(matches, (match) async {
      String radicals = match[1];
      //remove all characters that are not a radical
      radicals = radicals.replaceAll(RegExp('[^$radicalsString]'), '');

      kanjis.add(await getKanjiFromRadicals(_dbKanji, radicals));
    });

    int index = 0;
    input = input.replaceAllMapped(exp, (Match m) {
      if (kanjis[index] == '') return m.group(0);
      return '[${kanjis[index++]}]';
    });

    //replace regexp japanese character to latin character
    input = input.replaceAll('。', '.');
    input = input.replaceAll('？', '?');
    input = input.replaceAll(charKanji, regexKanji);
    input = input.replaceAll(charKana, regexKana);

    return input;
  }
}
