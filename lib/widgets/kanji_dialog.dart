import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/kanji.dart';
import '../services/database_interface_kanji.dart';
import 'kanji_list_tile.dart';

class KanjiDialog extends StatelessWidget {
  final List<String> literals;
  final DatabaseInterfaceKanji databaseInterfaceKanji;

  const KanjiDialog({
    required this.databaseInterfaceKanji,
    required this.literals,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: FutureBuilder<List<Kanji>>(
        future: databaseInterfaceKanji.getCharactersFromLiterals(literals),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<Kanji> sortedCharacters = List.from(snapshot.data!)
              ..sort(
                (a, b) =>
                    literals.indexOf(a.literal) - literals.indexOf(b.literal),
              );
            return ListView.separated(
              shrinkWrap: true,
              separatorBuilder: (context, index) {
                return const Divider();
              },
              itemCount: sortedCharacters.length,
              itemBuilder: (BuildContext context, int index) {
                return KanjiListTile(
                  onTap: null,
                  onTapLeading: () => Clipboard.setData(
                    ClipboardData(text: sortedCharacters[index].literal),
                  ),
                  selected: false,
                  kanji: sortedCharacters[index],
                );
              },
            );
          } else if (snapshot.hasError) {
            return ListTile(title: Text("${snapshot.error}"));
          }

          return ListView(
            shrinkWrap: true,
            children: const [
              ListTile(title: Center(child: CircularProgressIndicator())),
            ],
          );
        },
      ),
    );
  }
}
