// @dart=2.9

import 'package:flutter/material.dart';

class SearchInput extends StatefulWidget {
  final VoidCallback onSubmitted;
  final void Function(bool) onFocusChanged;
  final TextEditingController textEditingController;

  SearchInput(
      this.textEditingController, this.onSubmitted, this.onFocusChanged);

  @override
  _SearchInputState createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      widget.onFocusChanged(_focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12),
      child: TextField(
        onSubmitted: (_) => widget.onSubmitted(),
        textInputAction: TextInputAction.search,
        style: TextStyle(fontSize: 32.0),
        controller: widget.textEditingController,
        focusNode: _focusNode,
        decoration: InputDecoration(hintText: 'Enter a search term'),
      ),
    );
  }
}
