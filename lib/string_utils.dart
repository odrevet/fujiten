import 'package:kana_kit/kana_kit.dart';

const kanaKit = KanaKit();

const String regexKanji = '[一-龯]';
const String regexKana = '[ぁ-んァ-ン]';
const String charKanji = 'Ⓚ';
const String charKana = '㋐';

String escape(String value) {
  return value.replaceAll('\'', '\'\'');
}

String sqlIn(List<String> input) {
  String res = '(';
  input.asMap().forEach((i, String element) {
    res += '"$element"';
    if (i < input.length - 1) res += ',';
  });

  return res + ')';
}

String addCharAtPosition(String s, String char, int? position,
    {bool repeat = false}) {
  if (!repeat) {
    if (s.length < position!) {
      return s;
    }
    String before = s.substring(0, position);
    String after = s.substring(position, s.length);
    return before + char + after;
  } else {
    if (position == 0) {
      return s;
    }
    StringBuffer buffer = new StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i != 0 && i % position! == 0) {
        buffer.write(char);
      }
      buffer.write(String.fromCharCode(s.runes.elementAt(i)));
    }
    return buffer.toString();
  }
}