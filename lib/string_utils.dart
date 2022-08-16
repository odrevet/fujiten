import 'package:kana_kit/kana_kit.dart';

const kanaKit = KanaKit();

const String regexKanji = '[一-龯]';
const String regexKana = '[ぁ-んァ-ン]';
const String charKanji = 'Ⓚ';
const String charKanjiJp = 'ⓚ';
const String charKana = '㋐';
const String charKanaJp = '㋐';

String addCharAtPosition(String s, String char, int position, {bool repeat = false}) {
  if (s.length < position) {
    return s;
  }
  return s.substring(0, position) + char + s.substring(position, s.length);
}
