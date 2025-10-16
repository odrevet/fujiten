import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cubits/expression_cubit.dart';
import 'cubits/input_cubit.dart';
import 'cubits/kanji_cubit.dart';
import 'cubits/search_options_cubit.dart';
import 'cubits/theme_cubit.dart';
import 'models/states/theme_state.dart';
import 'services/database_interface_expression.dart';
import 'services/database_interface_kanji.dart';
import 'widgets/main_widget.dart';
import 'package:dynamic_color/dynamic_color.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load theme preference before running app
  final prefs = await SharedPreferences.getInstance();
  final isDarkTheme = prefs.getBool("darkTheme") ?? false;

  runApp(App(isDarkTheme: isDarkTheme));
}

class App extends StatelessWidget {
  final bool isDarkTheme;

  const App({super.key, required this.isDarkTheme});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return BlocProvider(
          create: (_) => ThemeCubit()..updateTheme(
            ThemeData(
              brightness: isDarkTheme ? Brightness.dark : Brightness.light,
            ),
          ),
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) => MultiBlocProvider(
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
                theme: themeState.themeData,
                home: MainWidget(),
              ),
            ),
          ),
        );

      },
    );

  }
}