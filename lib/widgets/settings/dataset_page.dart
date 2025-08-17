import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/widgets/settings/database_settings_widget.dart';

import '../../cubits/expression_cubit.dart';
import '../../cubits/kanji_cubit.dart';

class DatasetPage extends StatefulWidget {

  const DatasetPage({super.key});

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
            type: "expression",
            databaseInterface: context
                .read<ExpressionCubit>()
                .databaseInterface,
          ),
          DatabaseSettingsWidget(
            type: "kanji",
            databaseInterface: context.read<KanjiCubit>().databaseInterface,
          ),
        ],
      ),
    );
  }
}
