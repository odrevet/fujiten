import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/search_options_cubit.dart';
import '../../cubits/expression_cubit.dart';
import '../../models/states/search_options_state.dart';

class SearchOptionsWidget extends StatefulWidget {
  const SearchOptionsWidget({super.key});

  @override
  State<SearchOptionsWidget> createState() => _SearchOptionsWidgetState();
}

class _SearchOptionsWidgetState extends State<SearchOptionsWidget> {
  bool _isTestingRegexp = true; // Start as testing
  bool _isRegexpAvailable = false;

  @override
  void initState() {
    super.initState();
    // Automatically test regexp availability when widget initializes
    _testRegexpAvailability();
  }

  Future<void> _testRegexpAvailability() async {
    setState(() {
      _isTestingRegexp = true;
    });

    try {
      final database = context.read<ExpressionCubit>().databaseInterface.database;
      await database!.rawQuery('SELECT * FROM r_ele WHERE reb_el REGEXP \'*\' LIMIT 1');

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
      if (context.read<SearchOptionsCubit>().state.useRegexp) {
        context.read<SearchOptionsCubit>().setUseRegexp(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchOptionsCubit, SearchOptionsState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Type Toggle
              SegmentedButton<SearchType>(
                segments: const [
                  ButtonSegment<SearchType>(
                    value: SearchType.expression,
                    label: Text('Expression'),
                    icon: Text('言', style: TextStyle(fontSize: 20)),
                  ),
                  ButtonSegment<SearchType>(
                    value: SearchType.kanji,
                    label: Text('Kanji'),
                    icon: Text('漢', style: TextStyle(fontSize: 20)),
                  ),
                ],
                selected: {state.searchType},
                onSelectionChanged: (Set<SearchType> selected) {
                  context.read<SearchOptionsCubit>().setSearchType(
                    selected.first,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Regexp Toggle (disabled if not available or still testing)
              SwitchListTile(
                title: Row(
                  children: [
                    const Expanded(child: Text('Use Regular Expressions')),
                    if (_isTestingRegexp)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (!_isRegexpAvailable)
                      Icon(
                        Icons.error_outline,
                        size: 16,
                        color: Colors.red[600],
                      ),
                  ],
                ),
                subtitle: Text(
                  _isTestingRegexp
                      ? 'Checking regexp availability...'
                      : _isRegexpAvailable
                      ? 'Enable regexp pattern matching'
                      : 'RegExp not available',
                  style: TextStyle(
                    color: !_isRegexpAvailable && !_isTestingRegexp
                        ? Colors.red[600]
                        : null,
                  ),
                ),
                value: state.useRegexp && _isRegexpAvailable,
                onChanged: (_isTestingRegexp || !_isRegexpAvailable)
                    ? null
                    : (bool value) {
                  context.read<SearchOptionsCubit>().setUseRegexp(value);
                },
              ),

              const SizedBox(height: 16),

              // Results Per Page Fields
              _buildResultsPerPageKanji(context, state),
              const SizedBox(height: 12),
              _buildResultsPerPageExpression(context, state),

              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsPerPageKanji(
      BuildContext context,
      SearchOptionsState state,
      ) {
    return _buildResultsPerPageField(
      context: context,
      title: 'Results per Page (Kanji)',
      value: state.resultsPerPageKanji,
      icon: Icons.translate,
      onChanged: (value) {
        context.read<SearchOptionsCubit>().setResultsPerPageKanji(value);
      },
    );
  }

  Widget _buildResultsPerPageExpression(
      BuildContext context,
      SearchOptionsState state,
      ) {
    return _buildResultsPerPageField(
      context: context,
      title: 'Results per Page (Expression)',
      value: state.resultsPerPageExpression,
      icon: Icons.language,
      onChanged: (value) {
        context.read<SearchOptionsCubit>().setResultsPerPageExpression(value);
      },
    );
  }

  Widget _buildResultsPerPageField({
    required BuildContext context,
    required String title,
    required int value,
    required IconData icon,
    required Function(int) onChanged,
  }) {
    final controller = TextEditingController(text: value.toString());

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                hintText: '20',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                isDense: true,
              ),
              onChanged: (text) {
                final newValue = int.tryParse(text);
                if (newValue != null && newValue > 0 && newValue <= 999) {
                  onChanged(newValue);
                }
              },
              validator: (text) {
                final value = int.tryParse(text ?? '');
                if (value == null || value <= 0) {
                  return 'Must be > 0';
                }
                if (value > 999) {
                  return 'Max 999';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<SearchOptionsCubit>().reset();
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search options updated!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Apply'),
          ),
        ),
      ],
    );
  }
}