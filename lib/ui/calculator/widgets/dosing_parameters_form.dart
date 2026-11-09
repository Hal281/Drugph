import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../widgets/child_pugh_sheet.dart';

/// Form inputs for patient clinical dosing parameters:
/// - Weight, Height, Age, SCr
/// - Serum Creatinine stability (AKI vs stable)
/// - Renal Replacement Therapy (RRT) modality
/// - Child-Pugh hepatic impairment classification & sheet calculator
/// - Patient biological sex
class DosingParametersForm extends StatelessWidget {
  final TextEditingController weightCtrl;
  final TextEditingController heightCtrl;
  final TextEditingController ageCtrl;
  final TextEditingController scrCtrl;
  final bool isScrStable;
  final ValueChanged<bool> onScrStableChanged;
  final RenalReplacementMode renalReplacementMode;
  final ValueChanged<RenalReplacementMode> onRrtChanged;
  final ChildPughClass hepaticImpairment;
  final int? lastChildPughScore;
  final void Function(ChildPughClass cpClass, int? score) onHepaticChanged;
  final Sex sex;
  final ValueChanged<Sex> onSexChanged;
  final bool isThai;
  final Color categoryColor;

  const DosingParametersForm({
    super.key,
    required this.weightCtrl,
    required this.heightCtrl,
    required this.ageCtrl,
    required this.scrCtrl,
    required this.isScrStable,
    required this.onScrStableChanged,
    required this.renalReplacementMode,
    required this.onRrtChanged,
    required this.hepaticImpairment,
    this.lastChildPughScore,
    required this.onHepaticChanged,
    required this.sex,
    required this.onSexChanged,
    required this.isThai,
    this.categoryColor = Colors.teal,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: categoryColor),
                const SizedBox(width: 8),
                Text(
                  t ? 'ข้อมูลผู้ป่วย' : 'Patient Data',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    weightCtrl,
                    t ? 'น้ำหนัก (kg)' : 'Weight (kg)',
                    Icons.monitor_weight_outlined,
                    key: const Key('calculator_weight_field'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    heightCtrl,
                    t ? 'ส่วนสูง (cm)' : 'Height (cm)',
                    Icons.height,
                    key: const Key('calculator_height_field'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    ageCtrl,
                    t ? 'อายุ (ปี)' : 'Age (years)',
                    Icons.cake_outlined,
                    key: const Key('calculator_age_field'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    scrCtrl,
                    t ? 'Cr (mg/dL)' : 'SCr (mg/dL)',
                    Icons.water_drop_outlined,
                    key: const Key('calculator_scr_field'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                t
                    ? 'ค่า SCr คงที่ (Stable / ไม่ใช่ AKI)'
                    : 'SCr is stable (No AKI)',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      isScrStable ? Colors.grey.shade800 : Colors.red,
                  fontWeight:
                      isScrStable ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              value: isScrStable,
              onChanged: (val) => onScrStableChanged(val ?? true),
            ),
            const SizedBox(height: 12),
            // Renal Replacement Therapy (RRT) Selector
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                t
                    ? 'การบำบัดทดแทนไต (Renal Replacement Therapy):'
                    : 'Renal Replacement Therapy (RRT):',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: SegmentedButton<RenalReplacementMode>(
                key: const Key('calculator_rrt_selector'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<RenalReplacementMode>(
                    value: RenalReplacementMode.none,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        t ? 'ไม่มี' : 'None',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const ButtonSegment<RenalReplacementMode>(
                    value: RenalReplacementMode.ihd,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'IHD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const ButtonSegment<RenalReplacementMode>(
                    value: RenalReplacementMode.capd,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CAPD',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const ButtonSegment<RenalReplacementMode>(
                    value: RenalReplacementMode.crrt,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CRRT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                selected: {renalReplacementMode},
                onSelectionChanged:
                    (Set<RenalReplacementMode> newSelection) {
                  onRrtChanged(newSelection.first);
                },
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 2),
                  ),
                  backgroundColor:
                      WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return categoryColor.withValues(alpha: 0.2);
                    }
                    return Colors.white;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Child-Pugh Hepatic Function Selector + Interactive Calculator Button
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  t
                      ? 'การทำงานของตับ (Child-Pugh):'
                      : 'Hepatic Function (Child-Pugh):',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 48,
                    minWidth: 48,
                  ),
                  child: TextButton.icon(
                    key: const Key('calculator_open_child_pugh_sheet_button'),
                    style: TextButton.styleFrom(
                      foregroundColor: categoryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () async {
                      final res = await ChildPughCalculatorSheet.show(
                        context,
                        isThai: t,
                        accentColor: categoryColor,
                      );
                      if (res != null) {
                        onHepaticChanged(res.classification, res.totalScore);
                      }
                    },
                    icon: const Icon(
                      Icons.calculate_outlined,
                      size: 18,
                    ),
                    label: Text(
                      lastChildPughScore != null
                          ? (t
                              ? 'คำนวณ Child-Pugh ($lastChildPughScore/15)'
                              : 'Child-Pugh Calc ($lastChildPughScore/15)')
                          : (t
                              ? 'คำนวณคะแนน Child-Pugh'
                              : 'Calculate Score'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: SegmentedButton<ChildPughClass>(
                key: const Key('calculator_child_pugh_selector'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<ChildPughClass>(
                    value: ChildPughClass.none,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        t ? 'ปกติ' : 'Normal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const ButtonSegment<ChildPughClass>(
                    value: ChildPughClass.classA,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Class A',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const ButtonSegment<ChildPughClass>(
                    value: ChildPughClass.classB,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Class B',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const ButtonSegment<ChildPughClass>(
                    value: ChildPughClass.classC,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Class C',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                selected: {hepaticImpairment},
                onSelectionChanged: (Set<ChildPughClass> newSelection) {
                  onHepaticChanged(newSelection.first, null);
                },
                style: ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 2),
                  ),
                  backgroundColor:
                      WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return categoryColor.withValues(alpha: 0.2);
                    }
                    return Colors.white;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Sex Selector
            SizedBox(
              width: double.infinity,
              height: 48,
              child: SegmentedButton<Sex>(
                segments: [
                  ButtonSegment(
                    value: Sex.male,
                    label: Text(t ? 'ชาย' : 'Male'),
                    icon: const Icon(Icons.male),
                  ),
                  ButtonSegment(
                    value: Sex.female,
                    label: Text(t ? 'หญิง' : 'Female'),
                    icon: const Icon(Icons.female),
                  ),
                ],
                selected: {sex},
                onSelectionChanged: (Set<Sex> newSelection) {
                  onSexChanged(newSelection.first);
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    Set<WidgetState> states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return categoryColor.withValues(alpha: 0.2);
                    }
                    return Colors.white;
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    Key? key,
  }) {
    return TextField(
      key: key,
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
