// ignore_for_file: avoid_print
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() {
  final all = DrugDatabase.allDrugs;
  print('Total drugs: ${all.length}');
  final unmapped = all.where((d) => d.effectiveDrugClass == null).toList();
  print('Unmapped drugs count: ${unmapped.length}');
  for (final d in unmapped) {
    print('- ${d.id}: ${d.genericName} [category: ${d.category.name}]');
  }
}
