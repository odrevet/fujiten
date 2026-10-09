import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/favorites_cubit.dart';
import '../../models/entry.dart';
import '../../models/favorite.dart';
import '../../services/favorites_ops.dart';
import '../kanji_list_tile.dart';
import '../result_expression_list.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

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

  Future<void> _renameList(BuildContext context, int index, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename list'),
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
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      if (!context.mounted) return;
      context.read<FavoritesCubit>().renameList(index, name.trim());
    }
  }

  Widget _buildItem(BuildContext context, int listIndex, Favorite favorite) {
    final entry = favorite.toEntry();
    final Widget content = entry is KanjiEntry
        ? KanjiListTile(kanji: entry.kanji, selected: false)
        : ResultExpressionList(searchResult: entry as ExpressionEntry);

    return Stack(
      children: [
        content,
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'Remove from list',
            onPressed: () =>
                context.read<FavoritesCubit>().removeFavorite(listIndex, favorite.id),
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(
    BuildContext context,
    int index,
    FavoriteList list,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.folder),
        title: Text(
          list.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${list.items.length} item(s)'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              tooltip: 'Rename',
              onPressed: () => _renameList(context, index, list.name),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              tooltip: 'Delete list',
              onPressed: () => context.read<FavoritesCubit>().deleteList(index),
            ),
          ],
        ),
        children: list.items.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No favorites in this list yet.'),
                ),
              ]
            : [
                for (final favorite in list.items)
                  _buildItem(context, index, favorite),
              ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final json = context.read<FavoritesCubit>().exportJson();
    await exportFavorites(json);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Favorites exported'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _import(BuildContext context) async {
    final json = await importFavorites();
    if (json == null) return;
    if (!context.mounted) return;
    final ok = context.read<FavoritesCubit>().importJson(json);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Favorites imported' : 'Invalid favorites file'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Favorites'),
            actions: [
              IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: 'Import',
                onPressed: () => _import(context),
              ),
              IconButton(
                icon: const Icon(Icons.download),
                tooltip: 'Export',
                onPressed: () => _export(context),
              ),
            ],
          ),
          body: state.lists.isEmpty
              ? const Center(child: Text('No favorite lists yet'))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    for (var i = 0; i < state.lists.length; i++)
                      _buildListSection(context, i, state.lists[i]),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _createList(context),
            tooltip: 'New list',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
