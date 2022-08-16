import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:japanese_dictionary/cubits/search_cubit.dart';

import 'widgets/main_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Japanese Dictionary",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.black,
        ),
      ),
      home: BlocProvider(create: (_) => SearchCubit(), child: MainWidget()),
    );
  }
}
