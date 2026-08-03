import 'package:flutter/material.dart';
import '../../../core/constants/property_options.dart';

class FilterPanel extends StatefulWidget {
  final String initialPropertyKind;
  final String initialPropCat;
  final String initialTenantType;
  final String initialToilet;
  final RangeValues initialRentRange;
  final RangeValues initialDepositRange;
  final Function(String, String, String, RangeValues, RangeValues) onApply;

  const FilterPanel({
    super.key,
    required this.initialPropertyKind,
    required this.initialPropCat,
    required this.initialTenantType,
    required this.initialToilet,
    required this.initialRentRange,
    required this.initialDepositRange,
    required this.onApply,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late String _propertyKind;
  late String _propCat;
  late String _tenantType;
  late String _toilet;
  late RangeValues _rentRange;
  late RangeValues _depositRange;

  static const double _rentMin = 0;
  static const double _rentMax = 1000000;
  static const double _depositMin = 0;
  static const double _depositMax = 1000000;

  @override
  void initState() {
    super.initState();
    _propertyKind = widget.initialPropertyKind;
    _propCat = widget.initialPropCat;
    _tenantType = widget.initialTenantType;
    _toilet = widget.initialToilet;
    _rentRange = widget.initialRentRange;
    _depositRange = widget.initialDepositRange;
  }

  String _formatAmount(double val) {
    if (val >= 100000) return '₹${(val / 100000).toStringAsFixed(1)}L';
    if (val >= 1000) return '₹${(val / 1000).toStringAsFixed(0)}K';
    return '₹${val.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      constraints: const BoxConstraints(maxHeight: 450),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Property Category',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  FilterChips(
                      options: _propertyKind == 'commercial'
                          ? PropertyOptions.commercialCategories
                          : PropertyOptions.residentialCategories,
                      selected: _propCat,
                      onSelect: (val) => setState(() => _propCat = val)),
                  const Divider(height: 24),
                  Text(
                      _propertyKind == 'commercial'
                          ? 'Suitable For'
                          : 'Allowed Tenants',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  FilterChips(
                      options: _propertyKind == 'commercial'
                          ? PropertyOptions.suitableFor
                          : const [
                              'Single Bachelor',
                              'Single Female',
                              'Family',
                              'Couple',
                              'Bachelor Group',
                              'Student',
                              'Worker'
                            ],
                      selected: _tenantType,
                      onSelect: (val) => setState(() => _tenantType = val)),
                  const Divider(height: 24),
                  const Text('Facilities (Toilet)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  FilterChips(
                      options: const ['Attached Toilet', 'Shared Toilet'],
                      selected: _toilet,
                      onSelect: (val) => setState(() => _toilet = val)),
                  const Divider(height: 24),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Rent Range',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                            '${_formatAmount(_rentRange.start)} - ${_formatAmount(_rentRange.end)}',
                            style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.bold)),
                      ]),
                  RangeSlider(
                      values: _rentRange,
                      min: _rentMin,
                      max: _rentMax,
                      divisions: 100,
                      activeColor: const Color(0xFFC62828),
                      onChanged: (val) => setState(() => _rentRange = val)),
                  const SizedBox(height: 12),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Deposit Amount Range',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(
                            '${_formatAmount(_depositRange.start)} - ${_formatAmount(_depositRange.end)}',
                            style: const TextStyle(
                                color: Color(0xFFC62828),
                                fontWeight: FontWeight.bold)),
                      ]),
                  RangeSlider(
                      values: _depositRange,
                      min: _depositMin,
                      max: _depositMax,
                      divisions: 100,
                      activeColor: const Color(0xFFC62828),
                      onChanged: (val) => setState(() => _depositRange = val)),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10)
            ]),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        side: const BorderSide(color: Color(0xFFC62828)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      setState(() {
                        _propCat = '';
                        _tenantType = '';
                        _toilet = '';
                        _rentRange = const RangeValues(_rentMin, _rentMax);
                        _depositRange =
                            const RangeValues(_depositMin, _depositMax);
                      });
                      widget.onApply(
                          '',
                          '',
                          '',
                          const RangeValues(_rentMin, _rentMax),
                          const RangeValues(_depositMin, _depositMax));
                    },
                    child: const Text('Reset',
                        style: TextStyle(
                            color: Color(0xFFC62828),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: const Color(0xFFC62828),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    onPressed: () => widget.onApply(_propCat, _tenantType,
                        _toilet, _rentRange, _depositRange),
                    child: const Text('Apply Filters',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class FilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Function(String) onSelect;

  const FilterChips(
      {super.key,
      required this.options,
      required this.selected,
      required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selected == option;
        return GestureDetector(
          onTap: () => onSelect(isSelected ? '' : option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFC62828) : Colors.white,
              border: Border.all(
                  color: isSelected
                      ? const Color(0xFFC62828)
                      : Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(option,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.black87)),
          ),
        );
      }).toList(),
    );
  }
}
