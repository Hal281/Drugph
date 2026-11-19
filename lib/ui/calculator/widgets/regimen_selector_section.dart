import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../theme/app_theme.dart';
import '../../widgets/clinical_evidence_sheet.dart';

/// Indication-driven dosing regimen dropdown selector (Lexicomp / Sanford Guide style)
/// with route abbreviations and interactive renal/hepatic adjustment chips.
class RegimenSelectorSection extends StatelessWidget {
  final Drug drug;
  final DosingRegimen? selectedRegimen;
  final ValueChanged<DosingRegimen?> onRegimenChanged;
  final OralLiquidConcentration? selectedLiquidConcentration;
  final ValueChanged<OralLiquidConcentration?>? onLiquidConcentrationChanged;
  final int? patientAgeYears;
  final double? patientWeightKg;
  final bool isThai;
  final Color categoryColor;

  const RegimenSelectorSection({
    super.key,
    required this.drug,
    required this.selectedRegimen,
    required this.onRegimenChanged,
    this.selectedLiquidConcentration,
    this.onLiquidConcentrationChanged,
    this.patientAgeYears,
    this.patientWeightKg,
    required this.isThai,
    this.categoryColor = AppTheme.primaryTeal,
  });

  @override
  Widget build(BuildContext context) {
    final t = isThai;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderDefault),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.medication_outlined,
                  color: AppTheme.primaryTeal,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t ? 'ข้อบ่งใช้ / วิธีบริหารยา' : 'Indication / Route',
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.inkPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildRegimenPill(
                  '${drug.regimens.length} ${t ? 'สูตร' : (drug.regimens.length == 1 ? 'Regimen' : 'Regimens')}',
                  AppTheme.primaryTealDark,
                  AppTheme.primaryTealSoft,
                  borderColor: AppTheme.primaryTealBorder,
                  key: const Key('regimen_count_badge'),
                ),
              ],
            ),
            if (drug.availableIndications.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                key: const Key('calculator_available_indications'),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderDefault),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t ? 'ข้อบ่งใช้หลัก' : 'Indications',
                      style: const TextStyle(
                        color: AppTheme.primaryTealDark,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...drug.availableIndications.map(
                      (indication) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• $indication',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.inkPrimary,
                          ),
                        ),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderStrong),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<DosingRegimen>(
                  isExpanded: true,
                  value: selectedRegimen,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: AppTheme.inkSecondary,
                  ),
                  items: drug.regimens
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text(
                            '${r.indication ?? "Standard"} (${r.route.abbreviation})',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.inkPrimary,
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
              const SizedBox(height: 10),
              Builder(
                builder: (context) {
                  final reg = selectedRegimen!;
                  final isPediatric =
                      reg.effectiveAudience == RegimenAudience.pediatric;
                  final doseSummary = formatRegimenDoseSummary(reg, t);
                  final clinicalNote = _resolveClinicalNote(reg, t);

                  final isPediatricPatient =
                      (patientAgeYears != null && patientAgeYears! < 18) ||
                          (patientAgeYears == null &&
                              patientWeightKg != null &&
                              patientWeightKg! > 0 &&
                              patientWeightKg! < 25.0);
                  final isAdultPatient =
                      patientAgeYears != null && patientAgeYears! >= 18;

                  final DosingRegimen? matchingPedRegimen = drug.regimens
                      .cast<DosingRegimen?>()
                      .firstWhere(
                        (r) => r?.effectiveAudience == RegimenAudience.pediatric,
                        orElse: () => null,
                      );
                  final DosingRegimen? matchingAdultRegimen = drug.regimens
                      .cast<DosingRegimen?>()
                      .firstWhere(
                        (r) => r?.effectiveAudience == RegimenAudience.adult,
                        orElse: () => null,
                      );

                  final DosingRegimen? recommendedSwitch;
                  final String? mismatchMessage;
                  if (isPediatricPatient &&
                      !isPediatric &&
                      matchingPedRegimen != null) {
                    recommendedSwitch = matchingPedRegimen;
                    mismatchMessage = t
                        ? 'คำเตือน: ผู้ป่วยเป็นเด็ก แต่สูตรที่เลือกเป็นสูตรสำหรับผู้ใหญ่ — แนะนำให้สลับไปใช้สูตรยาเด็ก'
                        : 'Warning: Pediatric patient is currently assigned an adult regimen. Switch to pediatric regimen?';
                  } else if (isAdultPatient &&
                      isPediatric &&
                      matchingAdultRegimen != null) {
                    recommendedSwitch = matchingAdultRegimen;
                    mismatchMessage = t
                        ? 'คำเตือน: ผู้ป่วยเป็นผู้ใหญ่ แต่สูตรที่เลือกเป็นสูตรสำหรับเด็ก — แนะนำให้สลับไปใช้สูตรยาผู้ใหญ่'
                        : 'Warning: Adult patient is currently assigned a pediatric regimen. Switch to adult regimen?';
                  } else {
                    recommendedSwitch = null;
                    mismatchMessage = null;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recommendedSwitch != null && mismatchMessage != null)
                        Container(
                          key: const Key('regimen_audience_mismatch_banner'),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.statusWarningBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.statusWarning,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: AppTheme.statusWarning,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  mismatchMessage,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF92400E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              TextButton(
                                key: const Key('regimen_audience_switch_button'),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  foregroundColor: const Color(0xFF78350F),
                                  backgroundColor: const Color(0xFFFEF3C7),
                                ),
                                onPressed: () =>
                                    onRegimenChanged(recommendedSwitch),
                                child: Text(
                                  t ? 'สลับสูตรทันที' : 'Switch',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _buildRegimenPill(
                            isPediatric
                                ? (t ? 'เด็ก (Pediatric)' : 'Pediatric')
                                : (t ? 'ผู้ใหญ่ (Adult)' : 'Adult'),
                            AppTheme.inkPrimary,
                            AppTheme.surfaceSubtle,
                            key: const Key('regimen_audience_pill'),
                          ),
                          if (doseSummary != null && doseSummary.isNotEmpty)
                            _buildRegimenPill(
                              doseSummary,
                              AppTheme.primaryTealDark,
                              AppTheme.primaryTealSoft,
                              borderColor: AppTheme.primaryTealBorder,
                              key: const Key('regimen_dose_rate_pill'),
                            ),
                          _buildRegimenPill(
                            t ? reg.route.nameTh : reg.route.nameEn,
                            AppTheme.inkSecondary,
                            AppTheme.surfaceSubtle,
                          ),
                          _buildRegimenPill(
                            t ? reg.dosingType.nameTh : reg.dosingType.nameEn,
                            AppTheme.inkSecondary,
                            AppTheme.surfaceSubtle,
                          ),
                          _buildRegimenPill(
                            t
                                ? reg.frequency.displayTh
                                : reg.frequency.displayEn,
                            AppTheme.inkSecondary,
                            AppTheme.surfaceSubtle,
                          ),
                          if (reg.renalAdjustments != null &&
                              reg.renalAdjustments!.isNotEmpty)
                            _buildInteractiveAdjustmentChip(
                              key: const Key('regimen_renal_adjusted_chip'),
                              label: t ? 'มีเกณฑ์ปรับตามไต' : 'Renal Adjusted',
                              onTap: () => ClinicalEvidenceSheet.show(
                                context,
                                drug: drug,
                                regimen: reg,
                                isThai: t,
                                initialSection: 'renal',
                              ),
                            ),
                          if (reg.population?.maxHepaticImpairment != null)
                            _buildInteractiveAdjustmentChip(
                              key: const Key('regimen_hepatic_adjusted_chip'),
                              label:
                                  t ? 'มีเกณฑ์ปรับตามตับ' : 'Hepatic Adjusted',
                              onTap: () => ClinicalEvidenceSheet.show(
                                context,
                                drug: drug,
                                regimen: reg,
                                isThai: t,
                                initialSection: 'hepatic',
                              ),
                            ),
                        ],
                      ),
                      if (clinicalNote != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          key: const Key('regimen_clinical_note_box'),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSubtle,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.borderDefault),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: AppTheme.inkSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  clinicalNote,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: AppTheme.inkPrimary,
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
                            color: AppTheme.primaryTealSoft,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppTheme.primaryTealBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.medication_liquid_outlined,
                                    size: 18,
                                    color: AppTheme.primaryTeal,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      t
                                          ? 'ความเข้มข้นยาน้ำในคลัง / ท้องตลาด (Commercial Formulation)'
                                          : 'Commercial Liquid Concentration',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryTealDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.borderStrong,
                                  ),
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
                                                color: AppTheme.inkPrimary,
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
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.inkSecondary,
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
    Color? borderColor,
    Key? key,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor ?? AppTheme.borderDefault),
      ),
      child: Text(
        text,
        softWrap: true,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInteractiveAdjustmentChip({
    required Key key,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      key: key,
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.statusWarningBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.statusWarningBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.open_in_new,
              size: 12,
              color: Color(0xFF92400E),
            ),
          ],
        ),
      ),
    );
  }
}
