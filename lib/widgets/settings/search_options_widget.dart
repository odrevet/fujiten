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
    return Scaffold(
      appBar: AppBar(title: const Text('Search Options')),
      body: BlocBuilder<SearchOptionsCubit, SearchOptionsState>(
        builder: (context, state) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Search Options',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Use Regexp Toggle with Test Button
                  _buildRegexpToggleWithTest(context, state),
                  const SizedBox(height: 16),

                  // Results Per Page for Kanji
                  _buildResultsPerPageKanji(context, state),
                  const SizedBox(height: 16),

                  // Results Per Page for Expression
                  _buildResultsPerPageExpression(context, state),
                  const SizedBox(height: 20),

                  // Action Buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRegexpToggleWithTest(BuildContext context, SearchOptionsState state) {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              state.useRegexp ? Icons.code : Icons.text_fields,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Use Regular Expressions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            // Test RegExp Button
            OutlinedButton.icon(
              onPressed: _isTestingRegexp ? null : _testRegexpAvailability,
              icon: _isTestingRegexp
                  ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)
              )
                  : const Icon(Icons.science, size: 16),
              label: Text(_isTestingRegexp ? 'Testing...' : 'Test'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: state.useRegexp,
              onChanged: (bool value) {
                context.read<SearchOptionsCubit>().setUseRegexp(value);
              },
            ),
          ],
        ),
        // Test Result Display
        if (_regexpTestResult != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
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
                  size: 16,
                  color: _regexpTestResult!.contains('available')
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
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
                IconButton(
                  onPressed: () => setState(() => _regexpTestResult = null),
                  icon: const Icon(Icons.close, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
              ],
            ),
          ),
        ],
      ],
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

    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'e.g. 20',
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
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            context.read<SearchOptionsCubit>().reset();
          },
          child: const Text('Reset to Defaults'),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Search options updated!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.check),
          label: const Text('Apply'),
        ),
      ],
    );
  }
}

class CompactSearchOptionsWidget extends StatefulWidget {
  const CompactSearchOptionsWidget({super.key});

  @override
  State<CompactSearchOptionsWidget> createState() => _CompactSearchOptionsWidgetState();
}

class _CompactSearchOptionsWidgetState extends State<CompactSearchOptionsWidget> {
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

              const SizedBox(height: 8),

              // Current results per page indicator
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Results per page:',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        '${context.read<SearchOptionsCubit>().currentResultsPerPage}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}