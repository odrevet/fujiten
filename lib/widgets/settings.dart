import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

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
                        builder: (context) => const DatasetPage()),
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
  const DatasetPage({Key? key}) : super(key: key);

  @override
  State<DatasetPage> createState() => _DatasetPageState();
}

class _DatasetPageState extends State<DatasetPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<String> _expressionPath;
  late Future<String> _kanjiPath;

  @override
  void initState() {
    super.initState();
    _expressionPath = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('expression_path') ?? "";
    });

    _kanjiPath = _prefs.then((SharedPreferences prefs) {
      return prefs.getString('kanji_path') ?? "";
    });
  }

  Future<void> _setPath(subject, path) async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      _expressionPath = path;
      prefs.setString('${subject}_path', path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Databases')),
        body: FutureBuilder<List<String>>(
            future: Future.wait([_expressionPath, _kanjiPath]),
            builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const CircularProgressIndicator();
                default:
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return ListView(
                      children: [
                        ListTile(
                          title: const Text("Expression"),
                          subtitle: Text(snapshot.data![0] ?? "no value"),
                          trailing: ElevatedButton(
                            onPressed: () => _pickFiles().then((value) => _setPath('expression', value![0].path!)),
                            child: const Text('Pick file'),
                          ),
                        ),
                        ListTile(
                          title: const Text("Kanji"),
                          subtitle: Text(snapshot.data![1] ?? "no value"),
                          trailing: ElevatedButton(
                            onPressed: () => _pickFiles().then((value) => _setPath('kanji', value![0].path!)),
                            child: const Text('Pick file'),
                          ),
                        ),
                      ],
                    );
                  }
              }
            }));
  }

  Future<List<PlatformFile>?> _pickFiles() async {
    try {
      return (await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        onFileLoading: (FilePickerStatus status) => print(status),
      ))
          ?.files;
    } on PlatformException catch (e) {
      print('Unsupported operation' + e.toString());
    } catch (e) {
      print(e.toString());
    }
    return null;
  }
}
