import 'package:flutter/material.dart';
import 'package:japanese_dictionary/widgets/database_settings_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
                          applicationLegalese: '''2022 Olivier Drevet All right reserved
This software uses data from JMDict, Kanjidic2, Radkfile by the Electronic Dictionary Research and Development Group
under the Creative Commons Attribution-ShareAlike Licence (V3.0)''');
                    })
                  })
        ]));
  }
}

class DatasetPage extends StatefulWidget {
  final Future<void> Function(String) setExpressionDb;
  final Future<void> Function(String) setKanjiDb;

  const DatasetPage({Key? key, required this.setExpressionDb, required this.setKanjiDb})
      : super(key: key);

  @override
  State<DatasetPage> createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Databases')),
        body: ListView(
          children: [
            DatabaseSettingsWidget(
                type: "expression", setDb: widget.setExpressionDb),
            DatabaseSettingsWidget(type: "kanji", setDb: widget.setKanjiDb)
          ],
        ));
  }
}
