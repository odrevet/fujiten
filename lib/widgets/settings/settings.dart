import 'package:flutter/material.dart';
import 'package:fujiten/widgets/settings/theme_settings.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'dataset_page.dart';

class SettingsPage extends StatelessWidget {
  final Future<void> Function(String) setExpressionDb;
  final Future<void> Function(String) setKanjiDb;

  const SettingsPage({Key? key, required this.setExpressionDb, required this.setKanjiDb})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Menu')),
        body: ListView(children: [
          ListTile(
              leading: const Icon(Icons.data_usage),
              title: const Text("Databases"),
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            DatasetPage(setExpressionDb: setExpressionDb, setKanjiDb: setKanjiDb)),
                  )),
          ListTile(
              leading: const Icon(Icons.palette),
              title: const Text("Brightness"),
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ThemeSettings()),
                  )),
          ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About"),
              onTap: () => {
                    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
                      String appName = packageInfo.appName;
                      String version = packageInfo.version;

                      showAboutDialog(
                          context: context,
                          applicationName: appName,
                          applicationVersion: version,
                          applicationLegalese: '''2022-2024 Olivier Drevet All right reserved
This software uses data from JMDict, Kanjidic2, Radkfile by the Electronic Dictionary Research and Development Group
under the Creative Commons Attribution-ShareAlike Licence (V3.0)''');
                    })
                  })
        ]));
  }
}
