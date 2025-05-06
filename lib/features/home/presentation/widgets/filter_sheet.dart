import 'package:flutter/material.dart';

class FilterSheet extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final Function(Map<String, dynamic>) onApply;

  const FilterSheet({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late Map<String, dynamic> _filters;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _filters = Map<String, dynamic>.from(widget.initialFilters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Cars',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPriceRange(),
                    const SizedBox(height: 16),
                    _buildFuelType(),
                    const SizedBox(height: 16),
                    _buildTransmission(),
                    const SizedBox(height: 16),
                    _buildSeats(),
                  ],
                ),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _filters.clear());
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply(_filters);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRange() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range (per day)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _filters['minPrice']?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min Price',
                  prefixText: '₹',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _filters['minPrice'] = int.parse(value);
                  } else {
                    _filters.remove('minPrice');
                  }
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: _filters['maxPrice']?.toString() ?? '',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max Price',
                  prefixText: '₹',
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _filters['maxPrice'] = int.parse(value);
                  } else {
                    _filters.remove('maxPrice');
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFuelType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fuel Type',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip(
              'Petrol',
              _filters['fuelType'] == 'Petrol',
              (selected) {
                setState(() {
                  if (selected) {
                    _filters['fuelType'] = 'Petrol';
                  } else {
                    _filters.remove('fuelType');
                  }
                });
              },
            ),
            _buildFilterChip(
              'Diesel',
              _filters['fuelType'] == 'Diesel',
              (selected) {
                setState(() {
                  if (selected) {
                    _filters['fuelType'] = 'Diesel';
                  } else {
                    _filters.remove('fuelType');
                  }
                });
              },
            ),
            _buildFilterChip(
              'Electric',
              _filters['fuelType'] == 'Electric',
              (selected) {
                setState(() {
                  if (selected) {
                    _filters['fuelType'] = 'Electric';
                  } else {
                    _filters.remove('fuelType');
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransmission() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transmission',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip(
              'Manual',
              _filters['transmission'] == 'Manual',
              (selected) {
                setState(() {
                  if (selected) {
                    _filters['transmission'] = 'Manual';
                  } else {
                    _filters.remove('transmission');
                  }
                });
              },
            ),
            _buildFilterChip(
              'Automatic',
              _filters['transmission'] == 'Automatic',
              (selected) {
                setState(() {
                  if (selected) {
                    _filters['transmission'] = 'Automatic';
                  } else {
                    _filters.remove('transmission');
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSeats() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of Seats',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildFilterChip(
              '2',
              _filters['seats'] == 2,
              (selected) {
                setState(() {
                  if (selected) {
                    _filters['seats'] = 2;
                  } else {
                    _filters.remove('seats');
                  }
                });
              },
            ),
            _buildFilterChip(
              '4',
              _filters['seats'] == 4,
              (selected) {
                setState(() {
                  if (selected) {
                    _filters['seats'] = 4;
                  } else {
                    _filters.remove('seats');
                  }
                });
              },
            ),
            _buildFilterChip(
              '6+',
              _filters['seats'] == 6,
              (selected) {
                setState(() {
                  if (selected) {
                    _filters['seats'] = 6;
                  } else {
                    _filters.remove('seats');
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool selected,
    Function(bool) onSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
    );
  }
} 