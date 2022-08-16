import 'package:flutter/material.dart';

class SearchInput extends StatefulWidget {
  final VoidCallback onSubmitted;
  final void Function(bool) onFocusChanged;
  final FocusNode focusNode;
  final TextEditingController textEditingController;

  const SearchInput(
      this.textEditingController, this.onSubmitted, this.onFocusChanged, this.focusNode,
      {Key? key})
      : super(key: key);

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      widget.onFocusChanged(widget.focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    widget.focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: TextField(
        onSubmitted: (_) => widget.onSubmitted(),
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 32.0),
        controller: widget.textEditingController,
        focusNode: widget.focusNode,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Enter a search term'),
      ),
    );
  }
}
