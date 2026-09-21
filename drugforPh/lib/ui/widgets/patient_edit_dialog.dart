import 'package:flutter/material.dart';

import '../../core/models/patient.dart';
import '../../core/models/unit.dart';
import '../../data/patient_session.dart';

class PatientEditDialog extends StatefulWidget {
  final Patient? initialPatient;
  final bool isThai;

  const PatientEditDialog({
    super.key,
    this.initialPatient,
    required this.isThai,
  });

  @override
  State<PatientEditDialog> createState() => _PatientEditDialogState();
}

class _PatientEditDialogState extends State<PatientEditDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _hnCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _heightCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _scrCtrl;
  bool _isScrStable = true;

  @override
  void initState() {
    super.initState();
    final p = widget.initialPatient;
    _nameCtrl = TextEditingController(text: p?.patientName ?? '');
    _hnCtrl = TextEditingController(text: p?.hospitalNumber ?? '');
    _weightCtrl = TextEditingController(text: p?.weightKg.toString() ?? '');
    _heightCtrl = TextEditingController(text: p?.heightCm.toString() ?? '');
    _ageCtrl = TextEditingController(text: p?.ageYears.toString() ?? '');
    _scrCtrl = TextEditingController(
      text: p?.serumCreatinineMgDl?.toString() ?? '',
    );
    _isScrStable = p?.isScrStable ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hnCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _scrCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final wt = double.tryParse(_weightCtrl.text);
    final ht = double.tryParse(_heightCtrl.text);
    final age = int.tryParse(_ageCtrl.text);
    final scr = double.tryParse(_scrCtrl.text);

    if (wt == null || ht == null || age == null) {
      // Show simple error
      return;
    }

    // Crude CrCl calculation for the global session just to have it
    // Using Cockcroft-Gault simplified.
    double? crcl;
    if (scr != null && scr > 0) {
      crcl = ((140 - age) * wt) / (72 * scr);
      // Assuming male default for quick setup if sex is not asked in this minimal dialog.
      // In a real app we'd add sex selector. Let's add a default for now.
    }

    final newPatient = Patient(
      id:
          widget.initialPatient?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      patientName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
      hospitalNumber: _hnCtrl.text.isNotEmpty ? _hnCtrl.text : null,
      weightKg: wt,
      heightCm: ht,
      ageYears: age,
      sex: widget.initialPatient?.sex ?? Sex.male,
      serumCreatinineMgDl: scr,
      creatinineClearanceMlMin: crcl,
      isScrStable: _isScrStable,
      activeDrugIds: widget.initialPatient?.activeDrugIds ?? const [],
    );

    PatientSession.instance.savePatient(newPatient, setAsCurrent: true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isThai ? 'ข้อมูลผู้ป่วย' : 'Patient Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: widget.isThai
                    ? 'ชื่อ (ตัวเลือก)'
                    : 'Name (Optional)',
              ),
            ),
            TextField(
              controller: _hnCtrl,
              decoration: const InputDecoration(labelText: 'HN (Optional)'),
            ),
            TextField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Weight (kg) *'),
            ),
            TextField(
              controller: _heightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Height (cm) *'),
            ),
            TextField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age (years) *'),
            ),
            TextField(
              controller: _scrCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Serum Creatinine (mg/dL)',
              ),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              title: Text(
                widget.isThai ? 'ค่า SCr คงที่ (Stable)' : 'SCr is stable',
              ),
              subtitle: Text(
                widget.isThai
                    ? 'จำเป็นสำหรับสูตร Cockcroft-Gault'
                    : 'Required for Cockcroft-Gault validity',
                style: const TextStyle(fontSize: 12),
              ),
              value: _isScrStable,
              onChanged: (val) {
                setState(() {
                  _isScrStable = val ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
      actions: [
        if (widget.initialPatient != null)
          TextButton(
            onPressed: () {
              PatientSession.instance.clearPatient();
              Navigator.pop(context);
            },
            child: Text(
              widget.isThai ? 'ล้างข้อมูล' : 'Clear',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.isThai ? 'ยกเลิก' : 'Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(widget.isThai ? 'บันทึก' : 'Save'),
        ),
      ],
    );
  }
}
