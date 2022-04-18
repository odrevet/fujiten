import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../lang.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Menu')),
        body: ListView(children: [
          ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Languages"),
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LanguagePage()),
                  )),
          ListTile(
              leading: const Icon(Icons.data_usage),
              title: const Text("Databases"),
              onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DatasetPage()),
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
                          applicationLegalese:
                              '''2022 Olivier Drevet All right reserved
This software uses data from JMDict, Kanjidic2, Radkfile by the Electronic Dictionary Research and Development Group
under the Creative Commons Attribution-ShareAlike Licence (V3.0)''');
                    })
                  })
        ]));
  }
}

class DatasetPage extends StatefulWidget {
  @override
  _DatasetPageState createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> {
  Map<String, dynamic>? _databases;

  @override
  void initState() {
    _getDatabasesList().then((assets) {
      assets!.removeWhere((key, value) => !key.startsWith('assets/db'));
      setState(() => _databases = assets);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Databases')),
        body: ListView.separated(
            separatorBuilder: (context, index) {
              return const Divider();
            },
            itemCount: _databases!.length,
            itemBuilder: (BuildContext context, int index) {
              String key = _databases!.keys.elementAt(index);
              return ListTile(title: Text(key));
            }));
  }

  Future<Map<String, dynamic>?> _getDatabasesList() async {
    final manifestContent =
        await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
    final Map<String, dynamic>? manifestMap = json.decode(manifestContent);
    return manifestMap;
  }
}

class LanguagePage extends StatefulWidget {
  @override
  _LanguagePageState createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  late SharedPreferences _sharedPreferences;
  late List<Lang> _langs;

  @override
  initState() {
    super.initState();
    _langs = <Lang>[];
    SharedPreferences.getInstance().then((sharedPreferences) {
      _sharedPreferences = sharedPreferences;

      List<String> prefLangs = _sharedPreferences.getStringList('langs') ??
          [
            'eng:1',
            'fre:0',
            'spa:0',
            'rus:0',
            'ger:0',
            'dut:0',
            'slv:0',
            'swe:0'
          ];

      for (var prefLang in prefLangs) {
        List<String> prefLangParsed = prefLang.split(':');
        setState(() {
          _langs.add(Lang(
              code: prefLangParsed[0], isEnabled: prefLangParsed[1] == '1'));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Language')),
        body: ListView.builder(
            itemCount: _langs.length,
            itemBuilder: (BuildContext context, int index) =>
                LangListTile(lang: _langs[index], onTap: _onTapLang)));
  }

  _onTapLang(Lang lang, bool? isEnabled) async {
    _langs.firstWhere((element) => element.code == lang.code).isEnabled =
        isEnabled!;

    List<String> langsSerialized = <String>[];
    for (var lang in _langs) {
      langsSerialized.add('${lang.code}:${lang.isEnabled == true ? '1' : '0'}');
    }
    print(langsSerialized.join());

    setState(() {
      _sharedPreferences.setStringList('langs', langsSerialized);
    });
  }
}

class LangListTile extends StatefulWidget {
  final Lang? lang;
  final dynamic Function(Lang, bool?)? onTap;

  const LangListTile({this.lang, this.onTap});

  @override
  _LangListTileState createState() => _LangListTileState();
}

class _LangListTileState extends State<LangListTile> {
  _onTap(bool? value) {
    setState(() {
      widget.lang!.isEnabled = value!;
    });
    widget.onTap!(widget.lang!, value);
  }

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
        title: Text(
          '${widget.lang!.countryFlag} ${widget.lang!.name}',
          style: const TextStyle(fontSize: 18),
        ),
        value: widget.lang!.isEnabled,
        onChanged: _onTap);
  }
}
