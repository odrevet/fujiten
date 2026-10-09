/// Web build does not support local KanjiVG files.
Future<String> downloadAndExtractKanjivg({
  required void Function(String) onProgress,
}) async {
  throw UnsupportedError('KanjiVG is not supported on web');
}

Future<String?> pickKanjivgDirectory() async => null;

Future<String?> readKanjivgSvg(String kanjivgPath, String codepoint) async =>
    null;
