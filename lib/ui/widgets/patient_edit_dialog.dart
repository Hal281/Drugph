import 'package:flutter/material.dart';

import '../../core/calculators/renal_calculator.dart';
import '../../core/models/patient.dart';
import '../../core/models/renal_replacement_mode.dart';
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
  late TextEditingController _ageMonthsCtrl;
  late TextEditingController _scrCtrl;
  late TextEditingController _allergiesCtrl;
  late Sex _sex;
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
    _ageMonthsCtrl =
        TextEditingController(text: p?.ageMonths?.toString() ?? '');
    _scrCtrl = TextEditingController(
      text: p?.serumCreatinineMgDl?.toString() ?? '',
    );
    _allergiesCtrl = TextEditingController(text: p?.allergies.join(', ') ?? '');
    _sex = p?.sex ?? Sex.male;
    _isScrStable = p?.isScrStable ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _hnCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _ageCtrl.dispose();
    _ageMonthsCtrl.dispose();
    _scrCtrl.dispose();
    _allergiesCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final wt = double.tryParse(_weightCtrl.text);
    final ht = double.tryParse(_heightCtrl.text);
    final age = int.tryParse(_ageCtrl.text);
    final ageMonths = int.tryParse(_ageMonthsCtrl.text);
    final scr = double.tryParse(_scrCtrl.text);

    if (wt == null || ht == null || age == null) {
      // Show simple error
      return;
    }

    // Precise renal clearance calculation: Cockcroft-Gault (Winter 2012 Auto-Weight) for >= 18y,
    // Bedside Schwartz eGFR for pediatric (< 18y)
    double? crcl;
    double? egfr;
    if (scr != null && scr > 0) {
      if (age >= 18) {
        crcl = RenalCalculator.cockcroftGaultAutoWeight(
          ageYears: age,
          weightKg: wt,
          heightCm: ht,
          sex: _sex,
          serumCreatinineMgDl: scr,
        );
      } else if (age >= 1 && ht > 0) {
        egfr = RenalCalculator.bedsideSchwartz(
          heightCm: ht,
          serumCreatinineMgDl: scr,
        );
      }
    }

    final allergies = _allergiesCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final newPatient = Patient(
      id: widget.initialPatient?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      patientName: _nameCtrl.text.isNotEmpty ? _nameCtrl.text : null,
      hospitalNumber: _hnCtrl.text.isNotEmpty ? _hnCtrl.text : null,
      weightKg: wt,
      heightCm: ht,
      ageYears: age,
      ageMonths: ageMonths,
      sex: _sex,
      serumCreatinineMgDl: scr,
      creatinineClearanceMlMin: crcl,
      eGfrMlMinPer173m2: egfr ?? (age < 18 ? widget.initialPatient?.eGfrMlMinPer173m2 : null),
      isScrStable: _isScrStable,
      isPregnant: widget.initialPatient?.isPregnant ?? false,
      hepaticImpairment: widget.initialPatient?.hepaticImpairment,
      renalReplacementMode: widget.initialPatient?.renalReplacementMode ??
          RenalReplacementMode.none,
      activeDrugIds: widget.initialPatient?.activeDrugIds ?? const [],
      allergies: allergies,
    );

    PatientSession.instance.savePatient(newPatient, setAsCurrent: true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isThai ? 'ข้อมูลผู้ป่วย' : 'Patient Data'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 4),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText:
                      widget.isThai ? 'ชื่อผู้ป่วย (ถ้ามี)' : 'Name (Optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hnCtrl,
                decoration: InputDecoration(
                  labelText: widget.isThai ? 'HN (ถ้ามี)' : 'HN (Optional)',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Sex>(
                initialValue: _sex,
                decoration: InputDecoration(
                  labelText: widget.isThai ? 'เพศกำเนิด *' : 'Biological Sex *',
                ),
                items: Sex.values
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(widget.isThai ? s.nameTh : s.nameEn),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _sex = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _weightCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.isThai ? 'น้ำหนัก (kg) *' : 'Weight (kg) *',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _heightCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.isThai ? 'ส่วนสูง (cm) *' : 'Height (cm) *',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            widget.isThai ? 'อายุ (ปี) *' : 'Age (years) *',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _ageMonthsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: widget.isThai
                            ? 'อายุ (เดือน 0–11)'
                            : 'Months (0–11)',
                        hintText: '0-11',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _scrCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: widget.isThai
                      ? 'ค่าการทำงานของไต SCr (mg/dL)'
                      : 'Serum Creatinine (mg/dL)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _allergiesCtrl,
                decoration: InputDecoration(
                  labelText: widget.isThai
                      ? 'ประวัติแพ้ยา (คั่นด้วย ,)'
                      : 'Allergies (comma separated)',
                  hintText:
                      widget.isThai ? 'เช่น Penicillin, Sulfa' : 'e.g. Penicillin, Sulfa',
                  prefixIcon: const Icon(Icons.warning_amber, color: Colors.red),
                ),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                title: Text(
                  widget.isThai ? 'ค่า SCr คงที่ (Stable)' : 'SCr is stable',
                ),
                subtitle: Text(
                  widget.isThai
                      ? 'จำเป็นสำหรับสูตร Cockcroft-Gault / Schwartz'
                      : 'Required for Cockcroft-Gault / Schwartz validity',
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
