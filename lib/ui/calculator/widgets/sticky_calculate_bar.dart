import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../iv_titration_screen.dart';

/// Sticky bottom calculate action bar with primary "Calculate Dose" button
/// and optional "IV Titration Table" launcher.
class StickyCalculateBar extends StatelessWidget {
  final Drug drug;
  final DosingRegimen? selectedRegimen;
  final VoidCallback onCalculate;
  final bool isThai;
  final Color categoryColor;

  const StickyCalculateBar({
    super.key,
    required this.drug,
    required this.selectedRegimen,
    required this.onCalculate,
    required this.isThai,
    this.categoryColor = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (selectedRegimen?.dosingType == DosingType.titrated &&
                  selectedRegimen?.effectiveStandardDilutionMgPerMl != null) ...[
                Expanded(
                  child: SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(
                          color: Colors.red.shade700,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => IVTitrationScreen(
                              drug: drug,
                              regimen: selectedRegimen!,
                              isThai: t,
                            ),
                          ),
                        );
                      },
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          t ? 'ตารางดริปยา' : 'Titration Table',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    key: const Key('calculator_calculate_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: categoryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onCalculate,
                    child: Text(
                      t ? 'คำนวณโดสยา' : 'Calculate Dose',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
