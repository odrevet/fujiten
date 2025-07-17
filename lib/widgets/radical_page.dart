import 'package:flutter/material.dart';

import '../models/kanji.dart';
import '../services/database_interface_kanji.dart';
import '../string_utils.dart';
import 'kanji_list_tile.dart';

class RadicalPage extends StatefulWidget {
  final DatabaseInterfaceKanji databaseInterfaceKanji;
  final List<String> selectedRadicals;

  const RadicalPage(
    this.databaseInterfaceKanji,
    this.selectedRadicals, {
    super.key,
  });

  @override
  RadicalPageState createState() => RadicalPageState();
}

class RadicalPageState extends State<RadicalPage> {
  Future<List<Kanji>>? _radicals;
  List<String?> _validRadicals = [];
  String filter = "";
  final TextEditingController filterController = TextEditingController();
  bool listViewDisplay = false;

  @override
  void initState() {
    _radicals = widget.databaseInterfaceKanji.getRadicals();

    if (widget.selectedRadicals.isNotEmpty) {
      widget.databaseInterfaceKanji
          .getRadicalsForSelection(widget.selectedRadicals)
          .then(
            (validRadicals) => setState(() => _validRadicals = validRadicals),
          );
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

        Widget body;

        if (snapshot.hasData) {
          var radicals = snapshot.data!;

          if (filter.isNotEmpty) {
            if (kanaKit.isRomaji(filter)) {
              radicals = radicals
                  .where(
                    (radical) => radical.meanings == null
                        ? false
                        : radical.meanings!.any(
                            (meaning) => meaning.contains(filter),
                          ),
                  )
                  .toList();
            } else if (kanaKit.isHiragana(filter)) {
              radicals = radicals
                  .where(
                    (radical) => radical.kun == null
                        ? false
                        : radical.kun!.any((kun) => kun.contains(filter)),
                  )
                  .toList();
            } else if (kanaKit.isKatakana(filter)) {
              radicals = radicals
                  .where(
                    (radical) => radical.on == null
                        ? false
                        : radical.on!.any((on) => on.contains(filter)),
                  )
                  .toList();
            }
          }

          body = Column(
            children: [
              Expanded(
                flex: 1,
                child: FutureBuilder<List<String>>(
                  future: widget.databaseInterfaceKanji
                      .getCharactersFromRadicals(widget.selectedRadicals),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<String>> snapshot,
                      ) {
                        if (snapshot.hasData) {
                          var buttonList = snapshot.data!
                              .map<Widget>((kanji) => kanjiButton(kanji))
                              .toList();
                          return ListView(
                            scrollDirection: Axis.horizontal,
                            children: buttonList,
                          );
                        } else {
                          return const Center(
                            child: Text("Matched Kanji will appears here"),
                          );
                        }
                      },
                ),
              ),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: filterController,
                        decoration: InputDecoration(
                          hintText: 'Filter by meaning, on yomi, kun yomi',
                          suffix: Align(
                            widthFactor: 1.0,
                            heightFactor: 1.0,
                            child: IconButton(
                              icon: const Icon(Icons.translate),
                              onPressed: convert,
                            ),
                          ),
                        ),
                        onChanged: (value) => setState(() {
                          filter = value;
                        }),
                      ),
                    ),
                    /*IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          filterController.text = "";
                          setState(() {
                            filter = "";
                          });
                        }),*/
                  ],
                ),
              ),
              Expanded(
                flex: 8,
                child: listViewDisplay == true
                    ? radicalListView(radicals)
                    : radicalGridView(radicals),
              ),
            ],
          );
        } else {
          body = const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            title: Text(widget.selectedRadicals.toString()),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () =>
                  Navigator.pop(context, [true, widget.selectedRadicals]),
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: 'Clear selection',
                onPressed: () {
                  setState(() => widget.selectedRadicals.clear());
                  updateSelection();
                },
              ),
              IconButton(
                icon: listViewDisplay
                    ? const Icon(Icons.list_rounded)
                    : const Icon(Icons.grid_4x4_sharp),
                tooltip: 'Toggle view',
                onPressed: () =>
                    setState(() => listViewDisplay = !listViewDisplay),
              ),
            ],
          ),
          body: body,
        );
      },
    );
  }

  Widget radicalListView(List<Kanji> radicals) {
    // remove not selectable radicals
    radicals = radicals
        .where(
          (radical) =>
              _validRadicals.isEmpty ||
              _validRadicals.contains(radical.literal),
        )
        .toList();

    return ListView.separated(
      itemCount: radicals.length,
      separatorBuilder: (BuildContext context, int index) => const Divider(),
      itemBuilder: (BuildContext context, int index) {
        var radical = radicals[index];
        bool selected = widget.selectedRadicals.contains(radical.literal);

        var kanjiListTile = KanjiListTile(
          kanji: radicals[index],
          onTap: () => onRadicalButtonPress(radical.literal),
          selected: selected,
        );

        return kanjiListTile;
      },
    );
  }

  Widget radicalGridView(List<Kanji> radicals) => GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 5,
    ),
    itemCount: radicals.length,
    itemBuilder: (BuildContext context, int index) {
      if (index == 0 ||
          radicals[index].strokeCount != radicals[index - 1].strokeCount) {
        return Stack(
          children: <Widget>[
            Positioned.fill(child: radicalButton(radicals[index])),
            Stack(
              children: [
                Icon(
                  Icons.bookmark,
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white
                      : Colors.black,
                ),
                Positioned(
                  top: 3,
                  left: 5,
                  child: Text(radicals[index].strokeCount.toString()),
                ),
              ],
            ),
          ],
        );
      } else {
        return radicalButton(radicals[index]);
      }
    },
  );

  updateSelection() => widget.databaseInterfaceKanji
      .getRadicalsForSelection(widget.selectedRadicals)
      .then((validRadicals) => setState(() => _validRadicals = validRadicals));

  onRadicalButtonPress(String character) {
    setState(() {
      widget.selectedRadicals.contains(character)
          ? widget.selectedRadicals.removeWhere((test) => test == character)
          : widget.selectedRadicals.add(character);
    });

    updateSelection();
  }

  Widget radicalButton(Kanji radical) => TextButton(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) =>
            states.contains(WidgetState.disabled) ? Colors.grey : null,
      ),
    ),
    onPressed:
        _validRadicals.isEmpty || _validRadicals.contains(radical.literal)
        ? () => onRadicalButtonPress(radical.literal)
        : null,
    child: Text(
      radical.literal,
      style: TextStyle(
        fontSize: 35,
        color: widget.selectedRadicals.contains(radical.literal)
            ? Colors.red
            : null,
      ),
    ),
  );

  Widget kanjiButton(String kanji) => TextButton(
    onPressed: () => Navigator.pop(context, [false, kanji]),
    child: Text(kanji, style: const TextStyle(fontSize: 35)),
  );
}
