import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ThemeCubit extends Cubit<ThemeData> {
  ThemeCubit() : super(ThemeData());
  void setBrightness(Brightness brightness) => emit(state.copyWith(brightness: brightness));
  void updateTheme(ThemeData themeData) => emit(themeData);
}
