import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/input_cubit.dart';

class SearchInput extends StatefulWidget {
  final VoidCallback onSubmitted;
  final void Function(bool) onFocusChanged;
  final FocusNode focusNode;
  final TextEditingController textEditingController;
  final VoidCallback? onConvert;

  const SearchInput(
      this.textEditingController,
      this.onSubmitted,
      this.onFocusChanged,
      this.focusNode, {
        this.onConvert,
        super.key,
      });

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant SearchInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocus);
      widget.focusNode.addListener(_onFocus);
    }
  }

  @override
  void dispose() {
    // The focusNode is owned by MainWidget, only remove our listener.
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  void _onFocus() => widget.onFocusChanged(widget.focusNode.hasFocus);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyJ, control: true): () =>
              widget.onConvert?.call(),
          const SingleActivator(LogicalKeyboardKey.keyJ, meta: true): () =>
              widget.onConvert?.call(),
        },
        child: TextField(
          onChanged: (text) => context.read<InputCubit>().setInput(text),
          onSubmitted: (_) => widget.onSubmitted(),
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 32.0),
          controller: widget.textEditingController,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            hintText: 'Enter a search term',
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => widget.onSubmitted(),
            ),
          ),
        ),
      ),
    );
  }
}