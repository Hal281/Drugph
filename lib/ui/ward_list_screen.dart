import 'package:flutter/material.dart';

import '../data/patient_session.dart';
import '../core/models/patient.dart';
import 'patient_dashboard_screen.dart';
import 'widgets/patient_edit_dialog.dart';

class WardListScreen extends StatelessWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChange;

  bool get isThai => currentLocale.languageCode == 'th';

  const WardListScreen({
    super.key,
    required this.currentLocale,
    required this.onLocaleChange,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isThai ? 'รายชื่อผู้ป่วย (Ward List)' : 'Ward Patient List',
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<Patient>>(
        valueListenable: PatientSession.instance.wardPatients,
        builder: (context, patients, child) {
          if (patients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isThai
                        ? 'ยังไม่มีรายชื่อผู้ป่วยในระบบ\n(แตะที่แบนเนอร์ด้านบนในหน้าหลักเพื่อเพิ่มผู้ป่วย)'
                        : 'No patients in the ward list yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final p = patients[index];
              return ValueListenableBuilder<Patient?>(
                valueListenable: PatientSession.instance.currentPatient,
                builder: (context, currentP, child) {
                  final isCurrent = currentP?.id == p.id;

                  return Card(
                    elevation: isCurrent ? 2 : 0,
                    color: isCurrent ? Colors.teal.shade50 : Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: isCurrent ? Colors.teal : Colors.grey.shade300,
                        width: isCurrent ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrent
                            ? Colors.teal
                            : Colors.grey.shade200,
                        child: Icon(
                          Icons.person,
                          color: isCurrent
                              ? Colors.white
                              : Colors.grey.shade500,
                        ),
                      ),
                      title: Text(
                        p.patientName ??
                            (isThai ? 'ผู้ป่วยไม่ระบุชื่อ' : 'Unknown Patient'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'HN: ${p.hospitalNumber ?? "-"}\n'
                        '${p.weightKg} kg | ${p.ageYears} yrs | SCr: ${p.serumCreatinineMgDl ?? "-"}',
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          PatientSession.instance.removePatient(p.id);
                        },
                      ),
                      onTap: () {
                        PatientSession.instance.setPatient(p);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PatientDashboardScreen(isThai: isThai),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => PatientEditDialog(isThai: isThai),
          );
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
