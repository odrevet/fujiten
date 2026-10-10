import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubits/input_cubit.dart';
import '../models/input.dart';

class SessionMenu extends StatelessWidget {
  final TextEditingController textEditingController;
  final VoidCallback onSearch;

  const SessionMenu({
    super.key,
    required this.textEditingController,
    required this.onSearch,
  });

  String _sessionLabel(SearchSession session, int index) {
    if (session.name.isNotEmpty) return session.name;
    return 'Session ${index + 1}';
  }

  void _switchToSession(BuildContext context, int index) {
    final input = context.read<InputCubit>().state;
    textEditingController.text = input.sessions[index].currentInput;
    context.read<InputCubit>().setSearchIndex(index);
  }

  void _selectHistory(BuildContext context, String term) {
    textEditingController.text = term;
    onSearch();
  }

  Future<void> _renameSession(BuildContext context, int index) async {
    final inputCubit = context.read<InputCubit>();
    final input = inputCubit.state;
    final controller = TextEditingController(
      text: input.sessions[index].name,
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename session'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: 'Session ${index + 1}'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null) {
      inputCubit.renameSession(index, name.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InputCubit, Input>(
      builder: (context, input) {
        final scheme = Theme.of(context).colorScheme;
        final currentIndex = input.searchIndex;

        return MenuAnchor(
          menuChildren: [
            for (var i = 0; i < input.sessions.length; i++) ...[
              if (i > 0) const Divider(),
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    onPressed: () => _switchToSession(context, i),
                    child: const Text('Switch to session'),
                  ),
                  const Divider(),
                  if (input.sessions[i].history.isEmpty)
                    const MenuItemButton(
                      onPressed: null,
                      child: Text('No history'),
                    )
                  else
                  // Newest first
                    for (final term in input.sessions[i].history.reversed)
                      MenuItemButton(
                        onPressed: () => _selectHistory(context, term),
                        child: Text(term),
                      ),
                  const Divider(),
                  MenuItemButton(
                    onPressed: () => _renameSession(context, i),
                    child: const Text('Rename'),
                  ),
                  MenuItemButton(
                    onPressed: () =>
                        context.read<InputCubit>().clearSessionHistory(i),
                    child: const Text('Clear history'),
                  ),
                  MenuItemButton(
                    onPressed: input.sessions.length > 1
                        ? () => context.read<InputCubit>().removeSession(i)
                        : null,
                    child: const Text('Remove session'),
                  ),
                ],
                style: i == currentIndex
                    ? ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    scheme.primaryContainer,
                  ),
                  foregroundColor: WidgetStatePropertyAll(
                    scheme.onPrimaryContainer,
                  ),
                )
                    : null,
                leadingIcon: i == currentIndex
                    ? const Icon(Icons.check, size: 18)
                    : null,
                child: Text(
                  _sessionLabel(input.sessions[i], i),
                  style: i == currentIndex
                      ? const TextStyle(fontWeight: FontWeight.bold)
                      : null,
                ),
              ),
            ],
            const Divider(),
            MenuItemButton(
              onPressed: () {
                context.read<InputCubit>().addSession();
                textEditingController.clear();
              },
              child: const Text('Add session'),
            ),
          ],
          builder: (context, controller, child) {
            return IconButton(
              icon: const Icon(Icons.list),
              tooltip: 'Sessions',
              onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
            );
          },
        );
      },
    );
  }
}