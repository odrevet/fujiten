

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'kanji.dart';
import 'queries.dart' show getRadicals;

class RadicalPage extends StatefulWidget {
  final Database? _dbKanji;
  final List<String> _selectedRadicals;

  RadicalPage(this._dbKanji, this._selectedRadicals, {Key? key})
      : super(key: key);

  @override
  RadicalPageState createState() => RadicalPageState(this._selectedRadicals);
}

class RadicalPageState extends State<RadicalPage> {
  Future<List<Kanji>>? _radicals;
  List<String> _selectedRadicals = [];
  List<String?> _validRadicals = [];

  RadicalPageState(List<String> initialRadicals) {
    initialRadicals.forEach((String radical) => _selectedRadicals.add(radical));
  }

  @override
  void initState() {
    _radicals = getRadicals(widget._dbKanji!);

    if (_selectedRadicals.isNotEmpty)
      _getRadicalsForSelection().then(
          (validRadicals) => setState(() => _validRadicals = validRadicals));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Kanji>>(
      future: _radicals,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text(snapshot.error as String));

        return Scaffold(
            appBar: AppBar(
                title: Text('Radicals'),
                leading: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () =>
                        Navigator.pop(context, _selectedRadicals))),
            body: snapshot.hasData
                ? Center(child: radicalGridView(snapshot.data!))
                : Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget radicalGridView(List<Kanji> radicals) {
    return GridView.builder(
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
        itemCount: radicals.length,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0 ||
              radicals[index].stroke != radicals[index - 1].stroke) {
            return Stack(
              children: <Widget>[
                Positioned.fill(
                  child: _radicalButton(radicals[index]),
                ),
                Stack(children: [
                  Icon(Icons.bookmark,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.white
                          : Colors.black),
                  Positioned(
                      top: 3,
                      left: 5,
                      child: Text(radicals[index].stroke.toString()))
                ]),
              ],
            );
          } else
            return _radicalButton(radicals[index]);
        });
  }

  _onRadicalButtonPress(String character) {
    setState(() {
      _selectedRadicals.contains(character)
          ? _selectedRadicals.removeWhere((test) => test == character)
          : _selectedRadicals.add(character);
    });

    _getRadicalsForSelection().then(
        (validRadicals) => setState(() => _validRadicals = validRadicals));
  }

  Widget _radicalButton(Kanji radical) => TextButton(
      child: Text(radical.character, style: TextStyle(
        fontSize: 40,
        color: _selectedRadicals.contains(radical.character)
            ? Color.fromARGB(255, 255, 0, 0)
            : Color.fromARGB(255, 0, 0, 255),
      )),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed))
              return Theme.of(context).colorScheme.primary;
            else if (states.contains(MaterialState.disabled))
              return Colors.grey;
            return null; // Use the component's default.
          },
        ),
      ),
      onPressed:
          _validRadicals.isEmpty || _validRadicals.contains(radical.character)
              ? () => _onRadicalButtonPress(radical.character)
              : null);

  Future<List<String?>> _getRadicalsForSelection() async {
    String sql = 'SELECT DISTINCT id_radical FROM kanji_radical WHERE id_kanji IN (';

    _selectedRadicals.asMap().forEach((i, radical) {
      sql += 'SELECT DISTINCT id_kanji FROM kanji_radical WHERE id_radical = "$radical"';
      if (i < _selectedRadicals.length - 1) sql += ' INTERSECT ';
    });

    sql += ')';

    final List<Map<String, dynamic>> radicalIdMaps =
        await widget._dbKanji!.rawQuery(sql);

    return List.generate(radicalIdMaps.length, (i) {
      return radicalIdMaps[i]['id_radical'];
    });
  }
}
