import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../models/calculator_ui_state.dart';

/// Ergonomic side-by-side Dual Copy Action Bar (WCAG AAA touch targets >= 48x48 dp).
///
/// Provides 1-tap clipboard copying for:
/// 1. Physician Electronic Health Record Order (`copy_his_order_button`)
/// 2. Clinical Pharmacist Progress Note (`copy_pharmacist_note_button`)
class ClinicalActionBar extends StatelessWidget {
  final CalculatorUiState state;
  final bool isThai;
  final Patient Function() onBuildPatient;

  const ClinicalActionBar({
    super.key,
    required this.state,
    required this.isThai,
    required this.onBuildPatient,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;
    final res = state.result;
    final reg = state.selectedRegimen;

    if (res == null || reg == null) {
      return const SizedBox.shrink();
    }

    Widget buildHisOrderButton() {
      return SizedBox(
        height: 48,
        child: ElevatedButton.icon(
          key: const Key('copy_his_order_button'),
          icon: const Icon(Icons.content_paste_go, size: 18),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              t
                  ? 'คัดลอกคำสั่งแพทย์ (HIS Order)'
                  : 'Copy HIS Order',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal.shade700,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            final p = state.lastEvaluatedPatient ?? onBuildPatient();
            final orderText = ClinicalOrderFormatter.formatHisOrder(
              patient: p,
              drug: state.drug,
              regimen: reg,
              result: res,
              isThai: t,
            );
            Clipboard.setData(ClipboardData(text: orderText));
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    t
                        ? 'คัดลอกคำสั่งแพทย์แล้ว: $orderText'
                        : 'Copied HIS Order: $orderText',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
          },
        ),
      );
    }

    Widget buildPharmacistNoteButton() {
      return SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          key: const Key('copy_pharmacist_note_button'),
          icon: const Icon(Icons.assignment, size: 18),
          label: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              t
                  ? 'คัดลอกบันทึกเภสัชกร (Pharmacist Note)'
                  : 'Copy Pharmacist Note',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.teal.shade900,
            side: BorderSide(color: Colors.teal.shade700, width: 1.5),
            minimumSize: const Size(0, 48),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            final p = state.lastEvaluatedPatient ?? onBuildPatient();
            final noteText = ClinicalOrderFormatter.formatPharmacistNote(
              patient: p,
              drug: state.drug,
              regimen: reg,
              result: res,
              isThai: t,
            );
            Clipboard.setData(ClipboardData(text: noteText));
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    t
                        ? 'คัดลอกบันทึกเภสัชกรแล้ว'
                        : 'Copied Pharmacist Note to clipboard',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 380;

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              buildHisOrderButton(),
              const SizedBox(height: 8),
              buildPharmacistNoteButton(),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: buildHisOrderButton()),
            const SizedBox(width: 12),
            Expanded(child: buildPharmacistNoteButton()),
          ],
        );
      },
    );
  }
}
