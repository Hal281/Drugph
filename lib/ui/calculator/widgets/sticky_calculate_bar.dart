import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../iv_titration_screen.dart';
import '../../theme/app_theme.dart';

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
    this.categoryColor = AppTheme.primaryTeal,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppTheme.borderDefault),
          ),
        ),
        child: SafeArea(
          child: Row(
            children: [
              if (selectedRegimen?.dosingType == DosingType.titrated &&
                  selectedRegimen?.effectiveStandardDilutionMgPerMl != null) ...[
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.statusCritical,
                        side: const BorderSide(
                          color: AppTheme.statusCritical,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('calculator_calculate_button'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    onPressed: onCalculate,
                    child: Text(
                      t ? 'คำนวณโดสยา' : 'Calculate Dose',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
