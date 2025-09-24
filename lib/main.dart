import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';

import 'cubits/expression_cubit.dart';
import 'cubits/input_cubit.dart';
import 'cubits/kanji_cubit.dart';
import 'cubits/search_options_cubit.dart';
import 'cubits/theme_cubit.dart';
import 'models/inflection.dart';
import 'services/database_interface_expression.dart';
import 'services/database_interface_kanji.dart';
import 'widgets/main_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const configData = '''
0	plain, negative, nonpast
1	polite, non-past
2	conditional
3	volitional
4	te-form
5	plain, past
6	plain, negative, past
7	passive
8	causative
9	potential or imperative
10	imperative
11	polite, past
12	polite, negative, non-past
13	polite, negative, past
14	polite, volitional
15	adj. -> adverb
16	adj., past
17	polite
18	polite, volitional
19	passive or potential
20	passive (or potential if Grp 2)
21	adj., negative
22	adj., negative, past
23	adj., past
24	plain verb
25	polite, te-form
\$
くなかった	い	22
くなか	い	22
かった	い	23
く	い	15
ました	る	1
ませんでした	る	13
ません	る	12
ましょう	る	18
ない	る	0
なかった	る	6
れば	る	2
よう	る	3
て	る	4
た	る	5
られ	る	20
させ	る	8
れ	る	9
''';

  // Initialize the deinflector
  JapaneseDeinflector.initialize(configData);

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, themeData) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => InputCubit()),
            BlocProvider(create: (_) => SearchCubit()),
            BlocProvider(create: (_) => SearchOptionsCubit()),
            BlocProvider(
              create: (_) => ExpressionCubit(DatabaseInterfaceExpression()),
            ),
            BlocProvider(create: (_) => KanjiCubit(DatabaseInterfaceKanji())),
          ],
          child: MaterialApp(
            title: "Fujiten",
            theme: themeData,
            home: MainWidget(),
          ),
        ),
      ),
    );
  }
}
