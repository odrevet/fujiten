import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/kanji_cubit.dart';
import '../models/kanji.dart';
import '../string_utils.dart';
import 'kanji_list_tile.dart';

class RadicalPage extends StatefulWidget {
  final List<String> selectedRadicals;

  const RadicalPage(this.selectedRadicals, {super.key});

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
    _radicals = context.read<KanjiCubit>().databaseInterface.getRadicals();

    if (widget.selectedRadicals.isNotEmpty) {
      context
          .read<KanjiCubit>()
          .databaseInterface
          .getRadicalsForSelection(widget.selectedRadicals)
          .then(
            (validRadicals) => setState(() => _validRadicals = validRadicals),
      );
    }
    super.initState();
  }

  Future<void> convert() async {
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

          // Check if we're in landscape mode and adjust layout accordingly
          final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
          final screenHeight = MediaQuery.of(context).size.height;
          final isSmallScreen = screenHeight < 600;

          body = Column(
            children: [
              // Matched Kanji List - Use fixed height in landscape mode
              Container(
                height: isLandscape && isSmallScreen ? 60 : null,
                child: isLandscape && isSmallScreen
                    ? _buildMatchedKanjiSection()
                    : Expanded(
                  flex: 1,
                  child: _buildMatchedKanjiSection(),
                ),
              ),
              // Search Field - Use fixed height in landscape mode
              Container(
                height: isLandscape && isSmallScreen ? 60 : null,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: isLandscape && isSmallScreen
                    ? _buildSearchField()
                    : Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSearchField(),
                  ),
                ),
              ),
              // Radicals Grid/List - Take remaining space
              Expanded(
                flex: isLandscape && isSmallScreen ? 1 : 8,
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

  Widget _buildMatchedKanjiSection() {
    return FutureBuilder<List<String>>(
      future: context
          .read<KanjiCubit>()
          .databaseInterface
          .getCharactersFromRadicals(widget.selectedRadicals),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
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
            child: Text("Matched Kanji will appear here"),
          );
        }
      },
    );
  }

  Widget _buildSearchField() {
    return Row(
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
      ],
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

  Widget radicalGridView(List<Kanji> radicals) {
    // Filter out invalid radicals before building the grid
    radicals = radicals
        .where(
          (radical) =>
      _validRadicals.isEmpty ||
          _validRadicals.contains(radical.literal),
    )
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate crossAxisCount based on screen width
        int crossAxisCount;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 5; // Mobile
        } else if (constraints.maxWidth < 900) {
          crossAxisCount = 10; // Tablet
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 15; // Small desktop
        } else {
          crossAxisCount = 20; // Large desktop
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
          ),
          itemCount: radicals.length,
          itemBuilder: (BuildContext context, int index) {
            if (index == 0 ||
                radicals[index].strokeCount !=
                    radicals[index - 1].strokeCount) {
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
      },
    );
  }

  Future<void> updateSelection() => context
      .read<KanjiCubit>()
      .databaseInterface
      .getRadicalsForSelection(widget.selectedRadicals)
      .then((validRadicals) => setState(() => _validRadicals = validRadicals));

  void onRadicalButtonPress(String character) {
    setState(() {
      widget.selectedRadicals.contains(character)
          ? widget.selectedRadicals.removeWhere((test) => test == character)
          : widget.selectedRadicals.add(character);
    });

    updateSelection();
  }

  Widget radicalButton(Kanji radical) => TextButton(
    onPressed: () => onRadicalButtonPress(radical.literal),
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