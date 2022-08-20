import 'dart:developer';

import 'package:flutter/material.dart';

import '../models/kanji.dart';
import '../services/database_interface_kanji.dart';
import '../string_utils.dart';
import 'convert_button.dart';

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
  String filter = "";
  final TextEditingController filterController = TextEditingController();

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

  convert() async {
    String input = filterController.text;
    if (kanaKit.isRomaji(input)) {
      filterController.text = kanaKit.toKana(input);
      setState(() {
        filter = filterController.text;
      });
    } else {
      filterController.text = kanaKit.toRomaji(input);
      setState(() {
        filter = filterController.text;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Kanji>>(
      future: _radicals,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }

        return Scaffold(
            appBar: AppBar(
                title: Text(widget.selectedRadicals.toString()),
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context, widget.selectedRadicals))),
            body: snapshot.hasData
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: filterController,
                              decoration: const InputDecoration(
                                  hintText: 'Filter by meaning, on yomi, kun yomi'),
                              onChanged: (value) => setState(() {
                                filter = value;
                              }),
                            ),
                          ),
                          IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {filterController.text = ""; setState(() {
                                filter = "";
                              });}),
                          ConvertButton(onPressed: convert)
                        ],
                      ),
                      Expanded(child: radicalGridView(snapshot.data!)),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget radicalGridView(List<Kanji> radicals) {
    if (filter.isNotEmpty) {
      if (kanaKit.isRomaji(filter)) {
        radicals = radicals
            .where((radical) => radical.meanings == null
                ? false
                : radical.meanings!.any((meaning) => meaning.contains(filter)))
            .toList();
      } else if (kanaKit.isHiragana(filter)) {
        radicals = radicals
            .where((radical) =>
                radical.kun == null ? false : radical.kun!.any((kun) => kun.contains(filter)))
            .toList();
      } else if (kanaKit.isKatakana(filter)) {
        radicals = radicals
            .where((radical) =>
                radical.on == null ? false : radical.on!.any((on) => on.contains(filter)))
            .toList();
      }
    }

    return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
        itemCount: radicals.length,
        itemBuilder: (BuildContext context, int index) {
          if (index == 0 || radicals[index].strokeCount != radicals[index - 1].strokeCount) {
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
                  Positioned(top: 3, left: 5, child: Text(radicals[index].strokeCount.toString()))
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
      onPressed: _validRadicals.isEmpty || _validRadicals.contains(radical.literal)
          ? () => onRadicalButtonPress(radical.literal)
          : null,
      child: Text(radical.literal,
          style: TextStyle(
            fontSize: 40,
            color: widget.selectedRadicals.contains(radical.literal) ? Colors.red : null,
          )));
}
