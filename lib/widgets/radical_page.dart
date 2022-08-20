import 'package:flutter/material.dart';

import '../models/kanji.dart';
import '../services/database_interface_kanji.dart';

class RadicalPage extends StatefulWidget {
  final DatabaseInterfaceKanji databaseInterfaceKanji;
  final List<String> selectedRadicals;

  const RadicalPage(this.databaseInterfaceKanji, this.selectedRadicals, {Key? key})
      : super(key: key);

  @override
  RadicalPageState createState() => RadicalPageState();
}

class RadicalPageState extends State<RadicalPage> {
  Future<List<Kanji>>? _radicals;
  List<String?> _validRadicals = [];

  @override
  void initState() {
    _radicals = widget.databaseInterfaceKanji.getRadicals();

    if (widget.selectedRadicals.isNotEmpty) {
      widget.databaseInterfaceKanji
          .getRadicalsForSelection(widget.selectedRadicals)
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
                  child: radicalButton(radicals[index]),
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
            return radicalButton(radicals[index]);
          }
        });
  }

  onRadicalButtonPress(String character) {
    setState(() {
      widget.selectedRadicals.contains(character)
          ? widget.selectedRadicals.removeWhere((test) => test == character)
          : widget.selectedRadicals.add(character);
    });

    widget.databaseInterfaceKanji
        .getRadicalsForSelection(widget.selectedRadicals)
        .then((validRadicals) => setState(() => _validRadicals = validRadicals));
  }

  Widget radicalButton(Kanji radical) => TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) =>
            states.contains(MaterialState.disabled) ? Colors.grey : null),
      ),
      onPressed: _validRadicals.isEmpty || _validRadicals.contains(radical.character)
          ? () => onRadicalButtonPress(radical.character)
          : null,
      child: Text(radical.character,
          style: TextStyle(
            fontSize: 40,
            color: widget.selectedRadicals.contains(radical.character)
                ? Colors.red
                : null,
          )));
}
