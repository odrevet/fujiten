import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';

import 'cubits/expression_cubit.dart';
import 'cubits/input_cubit.dart';
import 'cubits/kanji_cubit.dart';
import 'cubits/search_options_cubit.dart';
import 'cubits/theme_cubit.dart';
import 'models/states/theme_state.dart';
import 'services/database_interface_expression.dart';
import 'services/database_interface_kanji.dart';
import 'widgets/main_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()..loadSavedTheme()),
        BlocProvider(create: (_) => InputCubit()),
        BlocProvider(create: (_) => SearchCubit()),
        BlocProvider(create: (_) => SearchOptionsCubit()),
        BlocProvider(
          create: (_) => ExpressionCubit(DatabaseInterfaceExpression()),
        ),
        BlocProvider(create: (_) => KanjiCubit(DatabaseInterfaceKanji())),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: "Fujiten",
            theme: themeState.themeData,
            darkTheme: _buildDarkTheme(themeState),
            themeMode: themeState.themeMode,
            home: MainWidget(),
          );
        },
      ),
    );
  }

  ThemeData _buildDarkTheme(ThemeState themeState) {
    // If using dynamic colors, create a dark version
    if (themeState.isDynamicColor ||
        themeState.useAccentColor ||
        themeState.customAccentColor != null) {
      final seedColor =
          themeState.customAccentColor ??
          themeState.themeData.colorScheme.primary;
      return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
    }

    // Default dark theme
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    );
  }
}
