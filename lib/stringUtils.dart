// @dart=2.9

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

String addCharAtPosition(String s, String char, int position,
    {bool repeat = false}) {
  if (!repeat) {
    if (s.length < position) {
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
      if (i != 0 && i % position == 0) {
        buffer.write(char);
      }
      buffer.write(String.fromCharCode(s.runes.elementAt(i)));
    }
    return buffer.toString();
  }
}

bool isKanjiCharacter(String character) => RegExp('[一-龯]').hasMatch(character);

bool isHiraganaCharacter(String character) =>
    RegExp('[ぁ-ん]').hasMatch(character);

bool isHiraganaString(String string) {
  for (int i = 0; i < string.length; i++) {
    if (!isHiraganaCharacter(string[i])) return false;
  }
  return true;
}

bool isKatakanaCharacter(String character) =>
    RegExp('[ァ-ン]').hasMatch(character);

bool isKatakanaString(String string) {
  for (int i = 0; i < string.length; i++) {
    if (!isKatakanaCharacter(string[i])) return false;
  }
  return true;
}

bool isJapaneseCharacter(String character) =>
    isKanjiCharacter(character) ||
    isHiraganaCharacter(character) ||
    isKatakanaCharacter(character);

bool isJapaneseString(String string) {
  for (int i = 0; i < string.length; i++) {
    if (!isJapaneseCharacter(string[i])) return false;
  }
  return true;
}

bool isLatinString(String string) => RegExp(r'^[\w ]*$').hasMatch(string);


