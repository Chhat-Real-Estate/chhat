import 'package:flutter/material.dart';
import '../../../core/constants/property_options.dart';

const Color _blueDark = Color(0xFF1A237E);

class OwnerFilterPanel extends StatefulWidget {
  final String initialType;
  final String initialBudget;
  final String initialMoveIn;
  final String propertyKind;
  final Function(String, String, String) onApply;

  const OwnerFilterPanel({
    super.key,
    required this.initialType,
    required this.initialBudget,
    required this.initialMoveIn,
    required this.propertyKind,
    required this.onApply,
  });

  @override
  State<OwnerFilterPanel> createState() => _OwnerFilterPanelState();
}

class _OwnerFilterPanelState extends State<OwnerFilterPanel> {
  late String _type;
  late String _budget;
  late String _moveIn;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _budget = widget.initialBudget;
    _moveIn = widget.initialMoveIn;
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
                  const Text('Tenant Type',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  OwnerFilterChips(
                      options: widget.propertyKind == 'commercial'
                          ? ['All Types', ...PropertyOptions.suitableFor]
                          : const [
                              'All Types',
                              'Single Bachelor',
                              'Single Female',
                              'Family',
                              'Couple',
                              'Student'
                            ],
                      selected: _type,
                      onSelect: (val) => setState(() => _type = val)),
                  const Divider(height: 24),
                  const Text('Budget',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  OwnerFilterChips(
                      options: const [
                        'All Budgets',
                        'Below ₹5,000',
                        '₹5,000 - ₹10,000',
                        '₹10,000 - ₹15,000',
                        'Above ₹20,000'
                      ],
                      selected: _budget,
                      onSelect: (val) => setState(() => _budget = val)),
                  const Divider(height: 24),
                  const Text('Move In',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.black87)),
                  const SizedBox(height: 10),
                  OwnerFilterChips(
                      options: const [
                        'Any Move-in',
                        'Immediately',
                        'Within 7 Days',
                        'Within 15 Days',
                        'Within 30 Days'
                      ],
                      selected: _moveIn,
                      onSelect: (val) => setState(() => _moveIn = val)),
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
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _blueDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => widget.onApply(_type, _budget, _moveIn),
                child: const Text('Apply Filters',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class OwnerFilterChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final Function(String) onSelect;

  const OwnerFilterChips(
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
          onTap: () => onSelect(isSelected ? (options.first) : option),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? _blueDark : Colors.white,
              border: Border.all(
                  color: isSelected ? _blueDark : Colors.grey.shade300),
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
