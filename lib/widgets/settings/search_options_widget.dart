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
  bool _isTestingRegexp = false;
  String? _regexpTestResult;

  Future<void> _testRegexpAvailability() async {
    setState(() {
      _isTestingRegexp = true;
      _regexpTestResult = null;
    });

    try {
      final database = context.read<ExpressionCubit>().databaseInterface.database;
      await database!.rawQuery('SELECT * FROM r_ele WHERE reb_el REGEXP \'*\' LIMIT 1');

      setState(() {
        _regexpTestResult = 'RegExp is available';
        _isTestingRegexp = false;
      });
    } catch (e) {
      setState(() {
        _regexpTestResult = 'RegExp not available: ${e.toString()}';
        _isTestingRegexp = false;
      });
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

              // Regexp Toggle with Test Button
              SwitchListTile(
                title: Row(
                  children: [
                    const Expanded(child: Text('Use Regular Expressions')),
                    OutlinedButton.icon(
                      onPressed: _isTestingRegexp ? null : _testRegexpAvailability,
                      icon: _isTestingRegexp
                          ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5)
                      )
                          : const Icon(Icons.science, size: 14),
                      label: Text(
                        _isTestingRegexp ? 'Testing...' : 'Test',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: const Size(0, 28),
                      ),
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Enable regexp pattern matching if available',
                ),
                value: state.useRegexp,
                onChanged: (bool value) {
                  context.read<SearchOptionsCubit>().setUseRegexp(value);
                },
              ),

              // Test Result Display
              if (_regexpTestResult != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _regexpTestResult!.contains('available')
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    border: Border.all(
                      color: _regexpTestResult!.contains('available')
                          ? Colors.green
                          : Colors.red,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _regexpTestResult!.contains('available')
                            ? Icons.check_circle
                            : Icons.error,
                        size: 14,
                        color: _regexpTestResult!.contains('available')
                            ? Colors.green
                            : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _regexpTestResult!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _regexpTestResult!.contains('available')
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => setState(() => _regexpTestResult = null),
                        child: const Icon(Icons.close, size: 14),
                      ),
                    ],
                  ),
                ),
              ],

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