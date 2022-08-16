import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../models/kanji.dart';
import '../services/database.dart' show getRadicals, getRadicalsForSelection;

class RadicalPage extends StatefulWidget {
  final Database? _dbKanji;
  final List<String> selectedRadicals;

  const RadicalPage(this._dbKanji, this.selectedRadicals, {Key? key}) : super(key: key);

  @override
  RadicalPageState createState() => RadicalPageState();
}

class RadicalPageState extends State<RadicalPage> {
  Future<List<Kanji>>? _radicals;
  List<String?> _validRadicals = [];

  @override
  void initState() {
    _radicals = getRadicals(widget._dbKanji!);

    if (widget.selectedRadicals.isNotEmpty) {
      getRadicalsForSelection(widget._dbKanji!, widget.selectedRadicals)
          .then((validRadicals) => setState(() => _validRadicals = validRadicals));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Kanji>>(
      future: _radicals,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error as String));
        }

        return Scaffold(
            appBar: AppBar(
                title: const Text('Radicals'),
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context, widget.selectedRadicals))),
            body: snapshot.hasData
                ? Center(child: radicalGridView(snapshot.data!))
                : const Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget radicalGridView(List<Kanji> radicals) {
    return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
        itemCount: radicals.length,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0 || radicals[index].stroke != radicals[index - 1].stroke) {
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
                  Positioned(top: 3, left: 5, child: Text(radicals[index].stroke.toString()))
                ]),
              ],
            );
          } else {
            return _radicalButton(radicals[index]);
          }
        });
  }

  _onRadicalButtonPress(String character) {
    setState(() {
      widget.selectedRadicals.contains(character)
          ? widget.selectedRadicals.removeWhere((test) => test == character)
          : widget.selectedRadicals.add(character);
    });

    getRadicalsForSelection(widget._dbKanji!, widget.selectedRadicals)
        .then((validRadicals) => setState(() => _validRadicals = validRadicals));
  }

  Widget _radicalButton(Kanji radical) => TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.pressed)) {
              return Theme.of(context).colorScheme.primary;
            } else if (states.contains(MaterialState.disabled)) {
              return Colors.grey;
            }
            return null; // Use the component's default.
          },
        ),
      ),
      onPressed: _validRadicals.isEmpty || _validRadicals.contains(radical.character)
          ? () => _onRadicalButtonPress(radical.character)
          : null,
      child: Text(radical.character,
          style: TextStyle(
            fontSize: 40,
            color: widget.selectedRadicals.contains(radical.character)
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondary,
          )));
}
