import 'package:flutter/material.dart';

class ConvertButton extends StatefulWidget {
  final Function onPressed;

  const ConvertButton({required this.onPressed, Key? key}) : super(key: key);

  @override
  State<ConvertButton> createState() => _ConvertButtonState();
}

class _ConvertButtonState extends State<ConvertButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 70,
        child: IconButton(
            icon: const Icon(Icons.translate), onPressed: widget.onPressed as void Function()?));
  }
}
