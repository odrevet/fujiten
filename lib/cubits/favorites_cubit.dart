import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorite.dart';

class FavoritesState {
  final List<FavoriteList> lists;

  FavoritesState({required this.lists});

  FavoritesState copyWith({List<FavoriteList>? lists}) =>
      FavoritesState(lists: lists ?? this.lists);

  bool isFavorite(int listIndex, String id) =>
      listIndex >= 0 &&
      listIndex < lists.length &&
      lists[listIndex].items.any((f) => f.id == id);

  bool isFavoriteAnywhere(String id) =>
      lists.any((l) => l.items.any((f) => f.id == id));
}

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit() : super(FavoritesState(lists: [])) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('favorites');
    if (json == null || json.isEmpty) return;
    try {
      final lists = (jsonDecode(json) as List)
          .map((e) => FavoriteList.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(FavoritesState(lists: lists));
    } catch (_) {}
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'favorites',
      jsonEncode(state.lists.map((l) => l.toJson()).toList()),
    );
  }

  void addList(String name) {
    emit(state.copyWith(lists: [...state.lists, FavoriteList(name: name)]));
    _save();
  }

  void renameList(int index, String name) {
    final lists = [...state.lists];
    lists[index] = FavoriteList(name: name, items: lists[index].items);
    emit(state.copyWith(lists: lists));
    _save();
  }

  void deleteList(int index) {
    final lists = [...state.lists]..removeAt(index);
    emit(state.copyWith(lists: lists));
    _save();
  }

  void addFavorite(int listIndex, Favorite favorite) {
    final lists = [...state.lists];
    final items = [...lists[listIndex].items];
    if (!items.any((f) => f.id == favorite.id)) {
      items.add(favorite);
    }
    lists[listIndex] = FavoriteList(name: lists[listIndex].name, items: items);
    emit(state.copyWith(lists: lists));
    _save();
  }

  void removeFavorite(int listIndex, String id) {
    final lists = [...state.lists];
    final items = lists[listIndex].items.where((f) => f.id != id).toList();
    lists[listIndex] = FavoriteList(name: lists[listIndex].name, items: items);
    emit(state.copyWith(lists: lists));
    _save();
  }

  String exportJson() =>
      jsonEncode(state.lists.map((l) => l.toJson()).toList());

  bool importJson(String json) {
    try {
      final lists = (jsonDecode(json) as List)
          .map((e) => FavoriteList.fromJson(e as Map<String, dynamic>))
          .toList();
      emit(FavoritesState(lists: lists));
      _save();
      return true;
    } catch (_) {
      return false;
    }
  }
}
