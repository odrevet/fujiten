import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fujiten/cubits/search_cubit.dart';

import 'cubits/input_cubit.dart';
import 'cubits/theme_cubit.dart';
import 'widgets/main_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, themeData) => MaterialApp(
          title: "Fujiten",
          theme: themeData,
          home: BlocProvider(
            create: (_) => InputCubit(),
            child: BlocProvider(
              create: (_) => SearchCubit(),
              child: MainWidget(),
            ),
          ),
        ),
      ),
    );
  }
}
