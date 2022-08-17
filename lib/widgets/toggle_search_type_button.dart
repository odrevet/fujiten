import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/search_cubit.dart';
import '../models/search.dart';

class ToggleSearchTypeButton extends StatefulWidget {
  const ToggleSearchTypeButton({Key? key}) : super(key: key);

  @override
  State<ToggleSearchTypeButton> createState() => _ToggleSearchTypeButtonState();
}

class _ToggleSearchTypeButtonState extends State<ToggleSearchTypeButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 70,
        child: TextButton(
            onPressed: () => context.read<SearchCubit>().toggleSearchType(),
            child: BlocBuilder<SearchCubit, Search>(builder: (context, search) {
              return Text(
                search.searchType == SearchType.kanji ? '漢字' : '言葉',
                style: const TextStyle(fontSize: 23.0, color: Colors.white),
              );
            })));
  }
}
