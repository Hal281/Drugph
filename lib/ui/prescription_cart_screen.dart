import 'package:flutter/material.dart';
import '../core/models/models.dart';
import '../data/prescription_cart.dart';
import 'theme/app_theme.dart';

class PrescriptionCartScreen extends StatelessWidget {
  final bool isThai;

  const PrescriptionCartScreen({super.key, required this.isThai});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppBar(
        title: Text(
          isThai
              ? 'ตรวจสอบรายการยาและปฏิกิริยาระหว่างยา'
              : 'Prescription Cart & DDI Check',
        ),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ValueListenableBuilder<List<Drug>>(
        valueListenable: PrescriptionCart.instance.items,
        builder: (context, drugs, child) {
          if (drugs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTealSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryTealBorder),
                      ),
                      child: const Icon(
                        Icons.medication_liquid_outlined,
                        size: 36,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isThai
                          ? 'ยังไม่มีรายการยาในใบสั่งยา'
                          : 'No medications in prescription cart',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.inkPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isThai
                          ? 'กดไอคอนตะกร้าในหน้าคำนวณยาเพื่อตรวจจับยาตีกัน (DDI) และยาซ้ำซ้อน'
                          : 'Add drugs from the calculator to check DDI and therapeutic duplication.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.inkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final alerts = PrescriptionCart.instance.evaluateAlerts();
          final primaryAlerts = alerts
              .where((a) =>
                  a.category != CartAlertCategory.ddi ||
                  a.frequency == InteractionFrequency.common)
              .toList();
          final lessCommonAlerts = alerts
              .where((a) =>
                  a.category == CartAlertCategory.ddi &&
                  a.frequency == InteractionFrequency.lessCommon)
              .toList();

          return ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              // Primary Alerts (Allergies, Therapeutic Duplication, & Common in Practice DDIs)
              if (primaryAlerts.isNotEmpty)
                Container(
                  key: const Key('cart_common_alerts_section'),
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.statusCriticalBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.statusCriticalBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppTheme.statusCritical,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isThai
                                  ? 'พบปฏิกิริยาระหว่างยาหรือข้อห้ามใช้ (พบบ่อย / สำคัญ)'
                                  : 'Clinically Significant Interactions & Contraindications',
                              style: const TextStyle(
                                color: AppTheme.statusCritical,
                                fontWeight: FontWeight.w700,
                                fontSize: 14.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...primaryAlerts.map(
                        (a) => _buildAlertEntry(a, isThai, textColor: const Color(0xFF991B1B)),
                      ),
                    ],
                  ),
                ),
              // Less-Common / Special Population DDIs (Collapsible)
              if (lessCommonAlerts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Material(
                    color: AppTheme.statusWarningBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.statusWarningBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        key: const Key('cart_less_common_ddi_tile'),
                        initiallyExpanded: false,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                        leading: const Icon(
                          Icons.info_outline_rounded,
                          color: AppTheme.statusWarning,
                          size: 20,
                        ),
                        title: Text(
                          isThai
                              ? 'คู่ยาที่พบน้อย / กลุ่มผู้ป่วยเฉพาะ (${lessCommonAlerts.length})'
                              : 'Less Common / Special Population DDIs (${lessCommonAlerts.length})',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        children: lessCommonAlerts
                            .map((a) => _buildAlertEntry(a, isThai, textColor: const Color(0xFF92400E)))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              if (alerts.isEmpty)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.statusSafeBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.statusSafeBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppTheme.statusSafe,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isThai
                              ? 'ไม่พบปฏิกิริยาระหว่างยาที่รุนแรง'
                              : 'No severe drug interactions found.',
                          style: const TextStyle(
                            color: Color(0xFF065F46),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Drug List
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: drugs.map((d) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: AppTheme.borderDefault),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryTealSoft,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.primaryTealBorder,
                            ),
                          ),
                          child: const Icon(
                            Icons.medication_outlined,
                            color: AppTheme.primaryTeal,
                          ),
                        ),
                        title: Text(
                          d.genericName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.inkPrimary,
                          ),
                        ),
                        subtitle: Text(
                          d.brandNames.join(', '),
                          style: const TextStyle(
                            color: AppTheme.inkSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTheme.inkMuted,
                          ),
                          tooltip: isThai ? 'ลบรายการ' : 'Remove',
                          onPressed: () {
                            PrescriptionCart.instance.removeDrug(d.id);
                          },
                        ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: AppTheme.borderDefault),
            ),
          ),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                PrescriptionCart.instance.clearCart();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isThai ? 'ล้างรายการยาแล้ว' : 'Cart cleared',
                    ),
                  ),
                );
              },
              child: Text(
                isThai ? 'ล้างรายการทั้งหมด' : 'Clear Cart',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertEntry(
    CartAlertItem alert,
    bool isThai, {
    required Color textColor,
  }) {
    final severityLabel =
        isThai ? alert.severity.labelTh : alert.severity.labelEn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  severityLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '• ${alert.localizedMessage(isThai)}',
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (alert.source != null && alert.source!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 2),
              child: Text(
                '${isThai ? "อ้างอิง" : "Source"}: ${alert.source}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: textColor.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
