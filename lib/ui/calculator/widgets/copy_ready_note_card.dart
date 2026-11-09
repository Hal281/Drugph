import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../models/calculator_ui_state.dart';

/// Pre-formatted monospaced clinical pharmacist note card with 1-click clipboard copy.
class CopyReadyNoteCard extends StatelessWidget {
  final CalculatorUiState state;
  final bool isThai;
  final Patient Function() onBuildPatient;

  const CopyReadyNoteCard({
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

    final p = state.lastEvaluatedPatient ?? onBuildPatient();
    final noteText = ClinicalOrderFormatter.formatPharmacistNote(
      patient: p,
      drug: state.drug,
      regimen: reg,
      result: res,
      isThai: t,
    );

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.content_paste,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t
                              ? 'ข้อความพร้อมคัดลอก (Copy-ready Note)'
                              : 'Copy-ready Note',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.blue),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: noteText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          t ? 'คัดลอกข้อความแล้ว' : 'Copied to clipboard',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            SelectableText(
              noteText,
              style: const TextStyle(
                fontFamily: 'Courier',
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
