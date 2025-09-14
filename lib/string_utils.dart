import 'package:fujiten/services/database_interface_kanji.dart';
import 'package:kana_kit/kana_kit.dart';

const kanaKit = KanaKit();

const String matchKanji = '[一-龯]';
const String matchKana = '[ぁ-んァ-ン]';

const String charKanji = 'Ⓚ';
const String charKanjiJp = 'ⓚ';
const String charKana = '㋐';
const String charKanaJp = '㋐';

String addCharAtPosition(String s, String char, int position) {
  if (s.length < position) {
    return s;
  }
  return s.substring(0, position) + char + s.substring(position, s.length);
}

Future<String> formatInput(
  String input,
  DatabaseInterfaceKanji databaseInterfaceKanji,
) async {
  input.trim().replaceAll(RegExp(r'\s+'), ' ');

  //replace every radicals into < > with matching kanji in [ ] for regexp
  List<List<String>> kanjis = [];
  var exp = RegExp(r'<(.*?)>');
  Iterable<RegExpMatch> matches = exp.allMatches(input);

  if (matches.isNotEmpty) {
    List<String?> radicalList = await databaseInterfaceKanji
        .getRadicalsCharacter();
    String radicalsString = radicalList.join();

    await Future.forEach(matches, (dynamic match) async {
      String radicals = match[1];
      //remove all characters that are not a radical
      radicals = radicals.replaceAll(RegExp('[^$radicalsString]'), '');
      var characters = await databaseInterfaceKanji.getCharactersFromRadicals(
        radicals.split(""),
      );
      kanjis.add(characters);
    });

    // replace the radicals <> width regex []
    int index = 0;
    input = input.replaceAllMapped(exp, (Match m) {
      if (kanjis[index].isEmpty) return m.group(0)!;
      return '[${kanjis[index++].join((','))}]';
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

  input = input.replaceAll(charKanji, matchKanji);
  input = input.replaceAll(charKanjiJp, matchKanji);
  input = input.replaceAll(charKana, matchKana);
  input = input.replaceAll(charKanaJp, matchKana);

  return input;
}
