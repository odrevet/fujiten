import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/expression_cubit.dart';
import '../../cubits/search_options_cubit.dart';
import '../../models/states/search_options_state.dart';

class SearchOptionsWidget extends StatefulWidget {
  const SearchOptionsWidget({super.key});

  @override
  State<SearchOptionsWidget> createState() => _SearchOptionsWidgetState();
}

class _SearchOptionsWidgetState extends State<SearchOptionsWidget> {
  bool _isTestingRegexp = true; // Start as testing
  bool _isRegexpAvailable = false;

  // Controllers for text fields
  late TextEditingController _kanjiController;
  late TextEditingController _expressionController;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    final state = context.read<SearchOptionsCubit>().state;
    _kanjiController = TextEditingController(
      text: state.resultsPerPageKanji.toString(),
    );
    _expressionController = TextEditingController(
      text: state.resultsPerPageExpression.toString(),
    );

    // Automatically test regexp availability when widget initializes
    _testRegexpAvailability();
  }

  @override
  void dispose() {
    _kanjiController.dispose();
    _expressionController.dispose();
    super.dispose();
  }

  Future<void> _testRegexpAvailability() async {
    setState(() {
      _isTestingRegexp = true;
    });

    try {
      final database = context
          .read<ExpressionCubit>()
          .databaseInterface
          .database;
      await database!.rawQuery(
        "SELECT id FROM gloss WHERE content REGEXP '.*' LIMIT 1",
      );

      setState(() {
        _isRegexpAvailable = true;
        _isTestingRegexp = false;
      });
    } catch (e) {
      setState(() {
        _isRegexpAvailable = false;
        _isTestingRegexp = false;
      });

      // Disable regexp if it's not available and currently enabled
      if (mounted && context.read<SearchOptionsCubit>().state.useRegexp) {
        context.read<SearchOptionsCubit>().setUseRegexp(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchOptionsCubit, SearchOptionsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Search Type Section
            _buildSectionHeader(context, 'Search For'),
            const SizedBox(height: 8),
            _buildSearchTypeSelector(context, state),
            const SizedBox(height: 24),

            // Regular Expressions Section
            if (_isTestingRegexp || _isRegexpAvailable) ...[
              _buildSectionHeader(context, 'Advanced Options'),
              const SizedBox(height: 8),
              _buildRegexpTile(context, state),
              const SizedBox(height: 24),
            ],

            // Results Per Page Section
            _buildSectionHeader(context, 'Results Per Page'),
            const SizedBox(height: 8),
            _buildResultsPerPageKanji(context, state),
            const SizedBox(height: 8),
            _buildResultsPerPageExpression(context, state),
            const SizedBox(height: 24),

            // Actions Section
            _buildSectionHeader(context, 'Actions'),
            const SizedBox(height: 8),
            _buildActionButtons(context),

            // Add some bottom padding
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSearchTypeSelector(
    BuildContext context,
    SearchOptionsState state,
  ) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SegmentedButton<SearchType>(
          showSelectedIcon: false,
          style: ButtonStyle(
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.primary;
              }
              return null;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.onPrimary;
              }
              return Theme.of(context).colorScheme.onSurface;
            }),
          ),
          segments: const [
            ButtonSegment<SearchType>(
              value: SearchType.expression,
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '言',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Expression',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            ButtonSegment<SearchType>(
              value: SearchType.kanji,
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '漢',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Kanji',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
          selected: {state.searchType},
          onSelectionChanged: (Set<SearchType> selected) {
            context.read<SearchOptionsCubit>().setSearchType(selected.first);
          },
        ),
      ),
    );
  }

  Widget _buildRegexpTile(BuildContext context, SearchOptionsState state) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Row(
          children: [
            const Expanded(child: Text('Use Regular Expressions')),
            if (_isTestingRegexp)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        subtitle: Text(
          _isTestingRegexp
              ? 'Checking regexp availability...'
              : 'Enable regexp pattern matching',
        ),
        value: state.useRegexp && _isRegexpAvailable,
        onChanged: _isTestingRegexp
            ? null
            : (bool value) {
                context.read<SearchOptionsCubit>().setUseRegexp(value);
              },
      ),
    );
  }

  Widget _buildResultsPerPageKanji(
    BuildContext context,
    SearchOptionsState state,
  ) {
    return _buildResultsPerPageCard(
      context: context,
      title: 'Kanji Results',
      value: state.resultsPerPageKanji,
      icon: Icons.translate,
      controller: _kanjiController,
      onChanged: (value) {
        context.read<SearchOptionsCubit>().setResultsPerPageKanji(value);
      },
    );
  }

  Widget _buildResultsPerPageExpression(
    BuildContext context,
    SearchOptionsState state,
  ) {
    return _buildResultsPerPageCard(
      context: context,
      title: 'Expression Results',
      value: state.resultsPerPageExpression,
      icon: Icons.language,
      controller: _expressionController,
      onChanged: (value) {
        context.read<SearchOptionsCubit>().setResultsPerPageExpression(value);
      },
    );
  }

  Widget _buildResultsPerPageCard({
    required BuildContext context,
    required String title,
    required int value,
    required IconData icon,
    required TextEditingController controller,
    required Function(int) onChanged,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        trailing: _buildIntegerInput(
          context: context,
          controller: controller,
          currentValue: value,
          onChanged: onChanged,
          min: 1,
          max: 999,
        ),
      ),
    );
  }

  Widget _buildIntegerInput({
    required BuildContext context,
    required TextEditingController controller,
    required int currentValue,
    required Function(int) onChanged,
    required int min,
    required int max,
  }) {
    return Container(
      width: 120,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrease button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                bottomLeft: Radius.circular(5),
              ),
              onTap: currentValue > min
                  ? () {
                      final newValue = currentValue - 1;
                      controller.text = newValue.toString();
                      onChanged(newValue);
                    }
                  : null,
              child: Container(
                width: 32,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.remove,
                  size: 16,
                  color: currentValue > min
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha:0.3),
                ),
              ),
            ),
          ),

          // Text input
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
                _RangeTextInputFormatter(min, max),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (text) {
                final newValue = int.tryParse(text);
                if (newValue != null && newValue >= min && newValue <= max) {
                  onChanged(newValue);
                }
              },
              onTap: () {
                // Select all text when tapped
                controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: controller.text.length,
                );
              },
              onFieldSubmitted: (text) {
                // Validate and correct the value on submit
                final newValue = int.tryParse(text);
                if (newValue == null || newValue < min) {
                  controller.text = min.toString();
                  onChanged(min);
                } else if (newValue > max) {
                  controller.text = max.toString();
                  onChanged(max);
                }
              },
            ),
          ),

          // Increase button
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(5),
                bottomRight: Radius.circular(5),
              ),
              onTap: currentValue < max
                  ? () {
                      final newValue = currentValue + 1;
                      controller.text = newValue.toString();
                      onChanged(newValue);
                    }
                  : null,
              child: Container(
                width: 32,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: currentValue < max
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha:0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<SearchOptionsCubit>().reset();
              // Update controllers with reset values
              final state = context.read<SearchOptionsCubit>().state;
              _kanjiController.text = state.resultsPerPageKanji.toString();
              _expressionController.text = state.resultsPerPageExpression
                  .toString();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset to Defaults'),
          ),
        ),
      ),
    );
  }
}

// Custom input formatter to enforce min/max range
class _RangeTextInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _RangeTextInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final int? value = int.tryParse(newValue.text);
    if (value == null) {
      return oldValue;
    }

    // Allow typing numbers that could become valid (e.g., typing "1" when max is 100)
    if (value > max) {
      // If the value is too large, don't allow it
      return oldValue;
    }

    return newValue;
  }
}
