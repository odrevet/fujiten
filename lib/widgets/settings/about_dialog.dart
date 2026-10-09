import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<void> showFujitenAboutDialog(BuildContext context) async {
  final packageInfo = await PackageInfo.fromPlatform();

  if (!context.mounted) return;

  final legalese = StringBuffer(
    '''2022-2026 Olivier Drevet All right reserved
This software uses data from JMDict, Kanjidic2, Radkfile by the Electronic Dictionary Research and Development Group
under the Creative Commons Attribution-ShareAlike Licence (V3.0)''',
  );

  if (!kIsWeb) {
    const bool ffiEnabled = bool.fromEnvironment('FFI', defaultValue: false);
    legalese.write(
      '\n\n${ffiEnabled ? 'Database: SQLite via FFI' : 'Database: SQLite native'}',
    );
  }

  showAboutDialog(
    context: context,
    applicationName: packageInfo.appName,
    applicationVersion: packageInfo.version,
    applicationLegalese: legalese.toString(),
  );
}