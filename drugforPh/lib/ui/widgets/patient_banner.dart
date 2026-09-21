import 'package:flutter/material.dart';

import '../../data/patient_session.dart';
import '../../core/models/patient.dart';
import '../../core/models/unit.dart';
import '../ward_list_screen.dart';
import 'patient_edit_dialog.dart';

class PatientBanner extends StatelessWidget {
  final bool isThai;

  const PatientBanner({super.key, required this.isThai});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Patient?>(
      valueListenable: PatientSession.instance.currentPatient,
      builder: (context, patient, child) {
        final hasPatient = patient != null;

        return Container(
          decoration: BoxDecoration(
            gradient: hasPatient
                ? LinearGradient(
                    colors: [Colors.teal.shade700, Colors.teal.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.orange.shade300, Colors.orange.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showPatientDialog(context, patient),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        hasPatient ? Icons.person : Icons.person_add,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hasPatient
                                ? (patient.patientName ??
                                      (isThai
                                          ? 'ผู้ป่วยปัจจุบัน'
                                          : 'Current Patient'))
                                : (isThai
                                      ? 'ยังไม่ได้ระบุผู้ป่วย'
                                      : 'No Patient Selected'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (hasPatient)
                            Text(
                              '${patient.weightKg} kg | ${patient.ageYears} yrs | CrCl: ${patient.creatinineClearanceMlMin?.toStringAsFixed(1) ?? "-"}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.teal.shade50,
                              ),
                            ),
                          if (!hasPatient)
                            Text(
                              isThai
                                  ? 'แตะเพื่อตั้งค่าข้อมูลผู้ป่วย'
                                  : 'Tap to set patient data',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.list_alt, color: Colors.white),
                        tooltip: isThai
                            ? 'รายชื่อผู้ป่วย (Ward List)'
                            : 'Ward List',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WardListScreen(
                                currentLocale: isThai ? const Locale('th', 'TH') : const Locale('en', 'US'),
                                onLocaleChange: (_) {},
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPatientDialog(BuildContext context, Patient? currentPatient) {
    showDialog(
      context: context,
      builder: (context) =>
          PatientEditDialog(initialPatient: currentPatient, isThai: isThai),
    );
  }
}
