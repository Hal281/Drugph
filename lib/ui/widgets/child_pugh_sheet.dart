import 'package:flutter/material.dart';

import '../../core/calculators/child_pugh_calculator.dart';
import '../../core/models/population_criteria.dart';

/// Interactive modal bottom sheet for deterministic Child-Pugh hepatic scoring.
class ChildPughCalculatorSheet extends StatefulWidget {
  final bool isThai;
  final Color accentColor;

  const ChildPughCalculatorSheet({
    super.key,
    required this.isThai,
    this.accentColor = Colors.teal,
  });

  /// Opens the interactive Child-Pugh calculator bottom sheet and returns
  /// the computed [ChildPughResult] when the clinician taps Apply.
  static Future<ChildPughResult?> show(
    BuildContext context, {
    required bool isThai,
    Color accentColor = Colors.teal,
  }) {
    return showModalBottomSheet<ChildPughResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ChildPughCalculatorSheet(
        isThai: isThai,
        accentColor: accentColor,
      ),
    );
  }

  @override
  State<ChildPughCalculatorSheet> createState() =>
      _ChildPughCalculatorSheetState();
}

class _ChildPughCalculatorSheetState extends State<ChildPughCalculatorSheet> {
  final _biliCtrl = TextEditingController(text: '1.0');
  final _albCtrl = TextEditingController(text: '4.0');
  final _inrCtrl = TextEditingController(text: '1.0');

  ChildPughAscites _ascites = ChildPughAscites.none;
  ChildPughEncephalopathy _encephalopathy = ChildPughEncephalopathy.none;

  @override
  void dispose() {
    _biliCtrl.dispose();
    _albCtrl.dispose();
    _inrCtrl.dispose();
    super.dispose();
  }

  ChildPughEvaluation _evaluateCurrent() {
    final bili = double.tryParse(_biliCtrl.text.trim());
    final alb = double.tryParse(_albCtrl.text.trim());
    final inr = double.tryParse(_inrCtrl.text.trim());
    return ChildPughCalculator.evaluate(
      totalBilirubinMgDl: bili,
      serumAlbuminGDl: alb,
      inr: inr,
      ascites: _ascites,
      encephalopathy: _encephalopathy,
    );
  }

  Color _classColor(ChildPughClass cls) {
    switch (cls) {
      case ChildPughClass.none:
      case ChildPughClass.classA:
        return Colors.teal.shade800;
      case ChildPughClass.classB:
        return Colors.amber.shade900;
      case ChildPughClass.classC:
        return Colors.red.shade800;
    }
  }

  Color _classBgColor(ChildPughClass cls) {
    switch (cls) {
      case ChildPughClass.none:
      case ChildPughClass.classA:
        return Colors.teal.shade50;
      case ChildPughClass.classB:
        return Colors.amber.shade50;
      case ChildPughClass.classC:
        return Colors.red.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.isThai;
    final evaluation = _evaluateCurrent();
    final res = evaluation.result;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        key: const Key('child_pugh_sheet_scroll'),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.biotech_rounded, color: widget.accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t
                        ? 'คำนวณระดับการทำงานของตับ (Child-Pugh Score)'
                        : 'Child-Pugh Hepatic Function Calculator',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: t ? 'ปิด' : 'Close',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Lab inputs: Bilirubin, Albumin, INR
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 160,
                  child: _buildNumericField(
                    key: const Key('child_pugh_bilirubin_field'),
                    controller: _biliCtrl,
                    label: t ? 'Total Bilirubin (mg/dL)' : 'Bilirubin (mg/dL)',
                    helper: '<2.0 (1) • 2–3 (2) • >3.0 (3)',
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: _buildNumericField(
                    key: const Key('child_pugh_albumin_field'),
                    controller: _albCtrl,
                    label: t ? 'Albumin (g/dL)' : 'Albumin (g/dL)',
                    helper: '>3.5 (1) • 2.8–3.5 (2) • <2.8 (3)',
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: _buildNumericField(
                    key: const Key('child_pugh_inr_field'),
                    controller: _inrCtrl,
                    label: 'INR',
                    helper: '<1.7 (1) • 1.7–2.3 (2) • >2.3 (3)',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              t ? 'ภาวะท้องมาน (Ascites):' : 'Ascites:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: SegmentedButton<ChildPughAscites>(
                key: const Key('child_pugh_ascites_selector'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ChildPughAscites.none,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t ? 'ไม่มี (1)' : 'None (1)'),
                    ),
                  ),
                  ButtonSegment(
                    value: ChildPughAscites.mildOrControlled,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t ? 'เล็กน้อย (2)' : 'Mild (2)'),
                    ),
                  ),
                  ButtonSegment(
                    value: ChildPughAscites.moderateToSevere,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t ? 'มาก/ดื้อยา (3)' : 'Mod-Sev (3)'),
                    ),
                  ),
                ],
                selected: {_ascites},
                onSelectionChanged: (sel) {
                  setState(() => _ascites = sel.first);
                },
              ),
            ),

            const SizedBox(height: 16),
            Text(
              t
                  ? 'อาการทางสมองจากโรคตับ (Hepatic Encephalopathy):'
                  : 'Hepatic Encephalopathy (West Haven):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: SegmentedButton<ChildPughEncephalopathy>(
                key: const Key('child_pugh_encephalopathy_selector'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ChildPughEncephalopathy.none,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t ? 'ไม่มี (1)' : 'None (1)'),
                    ),
                  ),
                  ButtonSegment(
                    value: ChildPughEncephalopathy.grade1To2,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t ? 'Gr I–II (2)' : 'Gr I–II (2)'),
                    ),
                  ),
                  ButtonSegment(
                    value: ChildPughEncephalopathy.grade3To4,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(t ? 'Gr III–IV (3)' : 'Gr III–IV (3)'),
                    ),
                  ),
                ],
                selected: {_encephalopathy},
                onSelectionChanged: (sel) {
                  setState(() => _encephalopathy = sel.first);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Live Score Result or Validation Error Card
            if (res != null)
              Container(
                key: const Key('child_pugh_result_badge'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _classBgColor(res.classification),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _classColor(res.classification),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t ? res.summaryTh : res.summaryEn,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _classColor(res.classification),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bili +${res.bilirubinPoints} • Alb +${res.albuminPoints} • INR +${res.inrPoints} • Ascites +${res.ascitesPoints} • Enceph +${res.encephalopathyPoints}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                key: const Key('child_pugh_validation_error'),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade400),
                ),
                child: Text(
                  t
                      ? (evaluation.errorTh ?? evaluation.errorEn ?? '')
                      : (evaluation.errorEn ?? ''),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                key: const Key('child_pugh_apply_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: res == null
                    ? null
                    : () => Navigator.of(context).pop(res),
                icon: const Icon(Icons.check_circle_outline),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    res != null
                        ? (t
                            ? 'ใช้ค่า ${res.classification.labelEn} (${res.totalScore}/15)'
                            : 'Apply ${res.classification.labelEn} (${res.totalScore}/15)')
                        : (t ? 'กรอกข้อมูลให้ครบถ้วน' : 'Enter valid lab values'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericField({
    required Key key,
    required TextEditingController controller,
    required String label,
    required String helper,
  }) {
    return TextField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 2,
        helperStyle: const TextStyle(fontSize: 10),
        isDense: true,
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
