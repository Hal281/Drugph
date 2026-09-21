import 'package:flutter/material.dart';

import '../core/models/patient.dart';
import '../core/models/drug.dart';
import '../core/calculators/tdm_calculator.dart';
import '../core/calculators/dose_rounder.dart';

class TdmScreen extends StatefulWidget {
  final Patient patient;
  final Drug drug;
  final bool isThai;

  const TdmScreen({
    super.key,
    required this.patient,
    required this.drug,
    required this.isThai,
  });

  @override
  State<TdmScreen> createState() => _TdmScreenState();
}

class _TdmScreenState extends State<TdmScreen> {
  double _maintDose = 1000.0;
  double _intervalHrs = 12.0;
  double _infusionTimeHrs = 1.0;

  @override
  Widget build(BuildContext context) {
    final patient = widget.patient;
    final crcl = patient.creatinineClearanceMlMin ?? 0.0;

    // --- PK Calculations ---
    final vd = TdmCalculator.calculateVd(weightKg: patient.weightKg);
    final ke = TdmCalculator.calculateKe(crclMlMin: crcl);
    final halfLife = TdmCalculator.calculateHalfLife(ke: ke);

    // --- Loading Dose ---
    final ldRange = TdmCalculator.calculateLoadingDose(
      weightKg: patient.weightKg,
    );
    final ldMinRounded = DoseRounder.roundToNearestStrength(ldRange[0], [
      250,
      500,
      750,
      1000,
      1250,
      1500,
      1750,
      2000,
    ]);
    final ldMaxRounded = DoseRounder.roundToNearestStrength(ldRange[1], [
      250,
      500,
      750,
      1000,
      1250,
      1500,
      1750,
      2000,
    ]);

    // --- Predicted Trough ---
    final predictedTrough = TdmCalculator.predictTrough(
      dose: _maintDose,
      tau: _intervalHrs,
      tInf: _infusionTimeHrs,
      vd: vd,
      ke: ke,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isThai
              ? 'การคำนวณ TDM: ${widget.drug.genericName}'
              : 'TDM: ${widget.drug.genericName}',
        ),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Patient summary
          Card(
            color: Colors.purple.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.isThai
                    ? 'น้ำหนัก: ${patient.weightKg} kg | CrCl: ${crcl.toStringAsFixed(1)} mL/min'
                    : 'Weight: ${patient.weightKg} kg | CrCl: ${crcl.toStringAsFixed(1)} mL/min',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // PK Parameters
          _SectionHeader(
            title: widget.isThai
                ? 'ค่าพารามิเตอร์ทางเภสัชจลนศาสตร์ (PK)'
                : 'PK Parameters',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Vd (0.7 L/kg)',
                    value: '${vd.toStringAsFixed(1)} L',
                  ),
                  const Divider(),
                  _InfoRow(label: 'Ke', value: '${ke.toStringAsFixed(4)} hr⁻¹'),
                  const Divider(),
                  _InfoRow(
                    label: 'Half-life (t½)',
                    value: '${halfLife.toStringAsFixed(1)} hr',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Loading Dose
          _SectionHeader(
            title: widget.isThai
                ? 'ขนาดยานำ (Loading Dose)'
                : 'Loading Dose (LD)',
          ),
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    widget.isThai
                        ? 'คำนวณที่ 25-30 mg/kg'
                        : 'Target: 25-30 mg/kg',
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(ldMinRounded ?? ldRange[0]).toStringAsFixed(0)} - ${(ldMaxRounded ?? ldRange[1]).toStringAsFixed(0)} mg',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Maintenance Dose Simulator
          _SectionHeader(
            title: widget.isThai
                ? 'จำลองระดับยา (Predicted Trough)'
                : 'Trough Simulator',
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _SpinnerNumberField(
                          label: widget.isThai ? 'ขนาดยา (mg)' : 'Dose (mg)',
                          value: _maintDose,
                          step: 250,
                          onChanged: (v) => setState(() => _maintDose = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _SpinnerNumberField(
                          label: widget.isThai
                              ? 'ความถี่ (hr)'
                              : 'Interval (hr)',
                          value: _intervalHrs,
                          step: 12, // Usually 12, 24, 36, 48
                          onChanged: (v) => setState(() => _intervalHrs = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getTroughColor(predictedTrough).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getTroughColor(predictedTrough),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          widget.isThai
                              ? 'ระดับยา Trough ที่คาดการณ์'
                              : 'Predicted Trough SS',
                          style: TextStyle(
                            color: _getTroughColor(predictedTrough).shade900,
                          ),
                        ),
                        Text(
                          '${predictedTrough.toStringAsFixed(1)} mg/L',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: _getTroughColor(predictedTrough).shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  MaterialColor _getTroughColor(double trough) {
    if (trough < 10) return Colors.orange;
    if (trough <= 20) return Colors.green;
    return Colors.red;
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.purple,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _SpinnerNumberField extends StatelessWidget {
  final String label;
  final double value;
  final double step;
  final ValueChanged<double> onChanged;

  const _SpinnerNumberField({
    required this.label,
    required this.value,
    required this.step,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > step ? () => onChanged(value - step) : null,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            Expanded(
              child: Text(
                value.toStringAsFixed(0),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged(value + step),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }
}
