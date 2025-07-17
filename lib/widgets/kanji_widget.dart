import 'package:flutter/material.dart';

import '../models/kanji.dart';

class KanjiCharacterWidget extends StatelessWidget {
  final Kanji? kanji;
  final VoidCallback? onTap;
  final bool displayFurigana;
  final String? furigana;
  final TextStyle? style;
  final TextStyle? styleFurigana;

  const KanjiCharacterWidget({
    required this.kanji,
    this.onTap,
    this.displayFurigana = true,
    this.furigana,
    required this.style,
    this.styleFurigana,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: furigana != null && displayFurigana
          ? Column(
              children: <Widget>[
                Text(furigana!, style: styleFurigana),
                Expanded(child: Text(kanji!.literal, style: style)),
              ],
            )
          : Text(kanji!.literal, style: style),
    );
  }
}
