import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/search_cubit.dart';
import '../cubits/search_options_cubit.dart';
import '../models/search.dart';
import '../models/states/search_options_state.dart';

class ToggleSearchTypeButton extends StatefulWidget {
  const ToggleSearchTypeButton({super.key});

  @override
  State<ToggleSearchTypeButton> createState() => _ToggleSearchTypeButtonState();
}

class _ToggleSearchTypeButtonState extends State<ToggleSearchTypeButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: TextButton(
        onPressed: () => context.read<SearchOptionsCubit>().toggleSearchType(),
        child: BlocBuilder<SearchCubit, Search>(
          builder: (context, search) {
            return Text(
              search.searchType == SearchType.kanji ? '漢' : '言',
              style: TextStyle(
                fontSize: 20.0,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}
