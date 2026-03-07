import 'package:flutter/material.dart';
import '../models/slot.dart';

class SlotChip extends StatelessWidget {
  final Slot slot;
  final bool isSelected;
  final VoidCallback onTap;

  const SlotChip({
    Key? key,
    required this.slot,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: slot.isAvailable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : slot.isAvailable
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot.displayStartTime,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : slot.isAvailable
                        ? Theme.of(context).primaryColor
                        : Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (!slot.isAvailable)
              const Text(
                'Booked',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}