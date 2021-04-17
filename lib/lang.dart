class Lang {
  String code;
  bool isEnabled;

  Lang({this.code, this.isEnabled});

  String get countryFlag {
    switch (code) {
      case 'fre':
        return '\u{1F1EB}\u{1F1F7}';
      case 'eng':
        return '\u{1F1EC}\u{1F1E7}';
      case 'ger':
        return '\u{1F1E9}\u{1F1EA}';
      case 'swe':
        return '\u{1F1F8}\u{1F1EA}';
      case 'spa':
        return '\u{1F1EA}\u{1F1F8}';
      case 'dut':
        return '\u{1F1F3}\u{1F1F1}';
      case 'hun':
        return '\u{1F1ED}\u{1F1FA}';
      case 'rus':
        return '\u{1F1F7}\u{1F1FA}';
      case 'slv':
        return '\u{1F1F8}\u{1F1FB}';
      default:
        return '[$code]';
    }
  }

  String get name {
    switch (code) {
      case 'fre':
        return 'French';
      case 'eng':
        return 'English';
      case 'ger':
        return 'German';
      case 'swe':
        return 'Swedish';
      case 'spa':
        return 'Spanish';
      case 'dut':
        return 'Dutch';
      case 'hun':
        return 'Hungarian';
      case 'rus':
        return 'Russian';
      case 'slv':
        return 'Salvador';
      default:
        return '[$code]';
    }
  }
}
