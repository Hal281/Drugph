import 'package:flutter/material.dart';

import '../../../core/core.dart';

/// Indication-driven dosing regimen dropdown selector (Lexicomp / Sanford Guide style)
/// with route abbreviations and renal/hepatic adjustment badges.
class RegimenSelectorSection extends StatelessWidget {
  final Drug drug;
  final DosingRegimen? selectedRegimen;
  final ValueChanged<DosingRegimen?> onRegimenChanged;
  final OralLiquidConcentration? selectedLiquidConcentration;
  final ValueChanged<OralLiquidConcentration?>? onLiquidConcentrationChanged;
  final bool isThai;
  final Color categoryColor;

  const RegimenSelectorSection({
    super.key,
    required this.drug,
    required this.selectedRegimen,
    required this.onRegimenChanged,
    this.selectedLiquidConcentration,
    this.onLiquidConcentrationChanged,
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
                Icon(Icons.vaccines, color: categoryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t ? 'ข้อบ่งใช้ / วิธีบริหารยา' : 'Indication / Route',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildRegimenPill(
                  '${drug.regimens.length} ${t ? 'สูตร' : (drug.regimens.length == 1 ? 'Regimen' : 'Regimens')}',
                  Color.lerp(categoryColor, Colors.black, 0.3) ?? categoryColor,
                  categoryColor.withValues(alpha: 0.12),
                  key: const Key('regimen_count_badge'),
                ),
              ],
            ),
            if (drug.availableIndications.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                key: const Key('calculator_available_indications'),
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t ? 'ข้อบ่งใช้หลัก' : 'Indications',
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...drug.availableIndications.map(
                      (indication) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $indication'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DosingRegimen>(
                  isExpanded: true,
                  value: selectedRegimen,
                  icon: const Icon(Icons.arrow_drop_down),
                  items: drug.regimens
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            '${r.indication ?? "Standard"} (${r.route.abbreviation})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: onRegimenChanged,
                ),
              ),
            ),
            if (selectedRegimen != null) ...[
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final reg = selectedRegimen!;
                  final isPediatric =
                      reg.effectiveAudience == RegimenAudience.pediatric;
                  final doseSummary = formatRegimenDoseSummary(reg, t);
                  final clinicalNote = _resolveClinicalNote(reg, t);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildRegimenPill(
                            isPediatric
                                ? (t ? 'เด็ก (Pediatric)' : 'Pediatric')
                                : (t ? 'ผู้ใหญ่ (Adult)' : 'Adult'),
                            isPediatric
                                ? Colors.deepPurple.shade800
                                : Colors.blue.shade900,
                            isPediatric
                                ? Colors.deepPurple.shade50
                                : Colors.blue.shade50,
                            key: const Key('regimen_audience_pill'),
                          ),
                          if (doseSummary != null && doseSummary.isNotEmpty)
                            _buildRegimenPill(
                              doseSummary,
                              Colors.cyan.shade900,
                              Colors.cyan.shade50,
                              key: const Key('regimen_dose_rate_pill'),
                            ),
                          _buildRegimenPill(
                            t ? reg.route.nameTh : reg.route.nameEn,
                            Colors.blueGrey.shade700,
                            Colors.blueGrey.shade50,
                          ),
                          _buildRegimenPill(
                            t ? reg.dosingType.nameTh : reg.dosingType.nameEn,
                            Colors.teal.shade800,
                            Colors.teal.shade50,
                          ),
                          _buildRegimenPill(
                            t
                                ? reg.frequency.displayTh
                                : reg.frequency.displayEn,
                            Colors.indigo.shade800,
                            Colors.indigo.shade50,
                          ),
                          if (reg.renalAdjustments != null &&
                              reg.renalAdjustments!.isNotEmpty)
                            _buildRegimenPill(
                              t ? 'มีเกณฑ์ปรับตามไต' : 'Renal Adjusted',
                              Colors.amber.shade900,
                              Colors.amber.shade50,
                            ),
                          if (reg.population?.maxHepaticImpairment != null)
                            _buildRegimenPill(
                              t ? 'มีเกณฑ์ปรับตามตับ' : 'Hepatic Adjusted',
                              Colors.orange.shade900,
                              Colors.orange.shade50,
                            ),
                        ],
                      ),
                      if (clinicalNote != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          key: const Key('regimen_clinical_note_box'),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.blueGrey.shade700,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  clinicalNote,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: Colors.blueGrey.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (reg.hasLiquidConcentrations) ...[
                        const SizedBox(height: 10),
                        Container(
                          key: const Key('regimen_liquid_concentration_box'),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.deepPurple.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.medication_liquid_rounded,
                                    size: 18,
                                    color: Colors.deepPurple.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      t
                                          ? 'ความเข้มข้นยาน้ำในคลัง / ท้องตลาด (Commercial Formulation)'
                                          : 'Commercial Liquid Concentration',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurple.shade900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.deepPurple.shade200),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<OralLiquidConcentration>(
                                    isExpanded: true,
                                    value: selectedLiquidConcentration ??
                                        reg.defaultLiquidConcentration,
                                    icon: const Icon(Icons.arrow_drop_down),
                                    items: reg.liquidConcentrations!
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(
                                              '${c.label}${c.brandOrForm != null ? " (${c.brandOrForm})" : ""}',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: onLiquidConcentrationChanged,
                                  ),
                                ),
                              ),
                              if ((selectedLiquidConcentration ??
                                          reg.defaultLiquidConcentration)
                                      ?.citation !=
                                  null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  t
                                      ? 'อ้างอิง: ${(selectedLiquidConcentration ?? reg.defaultLiquidConcentration)!.citation!}'
                                      : 'Ref: ${(selectedLiquidConcentration ?? reg.defaultLiquidConcentration)!.citation!}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.deepPurple.shade700,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Formats a concise dosing rate/basis label for the selected regimen.
  static String? formatRegimenDoseSummary(DosingRegimen reg, bool isThai) {
    final unit = reg.doseUnit.symbol;
    final basisSuffix = _formatBasisSuffix(reg.doseBasis, isThai);
    return switch (reg.dosingType) {
      DosingType.fixed => reg.fixedDose != null
          ? '${_formatNumber(reg.fixedDose!)} $unit$basisSuffix'
          : null,
      DosingType.weightBased => () {
          if (reg.minDosePerKg != null && reg.maxDosePerKg != null) {
            return '${_formatNumber(reg.minDosePerKg!)}–${_formatNumber(reg.maxDosePerKg!)} $unit/kg$basisSuffix';
          }
          if (reg.dosePerKg != null) {
            return '${_formatNumber(reg.dosePerKg!)} $unit/kg$basisSuffix';
          }
          return null;
        }(),
      DosingType.bsaBased => reg.dosePerM2 != null
          ? '${_formatNumber(reg.dosePerM2!)} $unit/m²$basisSuffix'
          : null,
      DosingType.gfrBased =>
        reg.targetAuc != null ? 'AUC ${_formatNumber(reg.targetAuc!)}' : null,
      DosingType.titrated => () {
          if (reg.continuousRateMin != null && reg.continuousRateMax != null) {
            final rateUnit = reg.continuousRateUnit ?? '';
            return '${_formatNumber(reg.continuousRateMin!)}–${_formatNumber(reg.continuousRateMax!)}${rateUnit.isNotEmpty ? ' $rateUnit' : ''}'
                .trim();
          }
          if (reg.fixedDose != null) {
            return '${_formatNumber(reg.fixedDose!)} $unit$basisSuffix';
          }
          return isThai ? 'ไตเตรทขนาดยา' : 'Titrated';
        }(),
      DosingType.renalAdjusted => reg.fixedDose != null
          ? '${_formatNumber(reg.fixedDose!)} $unit$basisSuffix'
          : null,
    };
  }

  static String _formatBasisSuffix(DoseBasis basis, bool isThai) {
    return switch (basis) {
      DoseBasis.perDay => isThai ? '/วัน' : '/day',
      DoseBasis.perWeek => isThai ? '/สัปดาห์' : '/wk',
      DoseBasis.perDose => isThai ? '/ครั้ง' : '/dose',
    };
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String? _resolveClinicalNote(DosingRegimen reg, bool isThai) {
    final primary = isThai ? reg.notesTh : reg.notes;
    if (primary != null && primary.trim().isNotEmpty) return primary.trim();
    final fallback = isThai ? reg.notes : reg.notesTh;
    if (fallback != null && fallback.trim().isNotEmpty) return fallback.trim();
    return null;
  }

  Widget _buildRegimenPill(
    String text,
    Color textColor,
    Color bgColor, {
    Key? key,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        softWrap: true,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
