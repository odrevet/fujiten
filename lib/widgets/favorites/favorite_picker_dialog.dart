import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/favorites_cubit.dart';
import '../../models/favorite.dart';

class FavoritePickerDialog extends StatelessWidget {
  final Favorite favorite;

  const FavoritePickerDialog({super.key, required this.favorite});

  Future<void> _createList(BuildContext context) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New list'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'List name'),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      if (!context.mounted) return;
      context.read<FavoritesCubit>().addList(name.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        return AlertDialog(
          title: const Text('Add to favorites'),
          content: SizedBox(
            width: double.maxFinite,
            child: state.lists.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No lists yet. Create one below.'),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (var i = 0; i < state.lists.length; i++)
                        ListTile(
                          leading: Icon(
                            state.isFavorite(i, favorite.id)
                                ? Icons.check_circle
                                : Icons.star_border,
                            color: state.isFavorite(i, favorite.id)
                                ? Colors.amber
                                : null,
                          ),
                          title: Text(state.lists[i].name),
                          onTap: () {
                            context
                                .read<FavoritesCubit>()
                                .addFavorite(i, favorite);
                            Navigator.of(context).pop();
                          },
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => _createList(context),
              child: const Text('New list'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
