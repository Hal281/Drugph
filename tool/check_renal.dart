// ignore_for_file: avoid_print
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  final all = DrugDatabase.allDrugs;
  print('Total drugs: ${all.length}');
  
  final missingTiers = <String>[];
  final secondaryMissing = <String>[];
  
  for (final d in all) {
    if (d.requiresRenalAdjustment) {
      final regWithTiers = d.regimens.where((r) => r.renalAdjustments != null && r.renalAdjustments!.isNotEmpty).toList();
      if (regWithTiers.isEmpty) {
        missingTiers.add('${d.id} (${d.genericName}) [${d.regimens.length} regimens]');
      } else if (regWithTiers.length < d.regimens.length) {
        final regWithout = d.regimens.where((r) => r.renalAdjustments == null || r.renalAdjustments!.isEmpty).map((r) => r.indication ?? r.route.name).toList();
        secondaryMissing.add('${d.id} (${d.genericName}): has tiers on ${regWithTiers.length}/${d.regimens.length} regimens. Missing on: ${regWithout.join(", ")}');
      }
    }
  }
  
  print('=== Drugs with requiresRenalAdjustment: true but NO renal adjustments on any regimen === (${missingTiers.length})');
  for (final m in missingTiers) {
    print('- $m');
  }
  
  print('\n=== Drugs with renal adjustments on some regimens but missing on secondary regimens === (${secondaryMissing.length})');
  for (final s in secondaryMissing) {
    print('- $s');
  }
}
