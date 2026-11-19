import 'package:flutter/material.dart';
import '../data/prescription_cart.dart';
import '../core/models/drug.dart';
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

          final warnings = PrescriptionCart.instance.checkInteractions(isThai);

          return Column(
            children: [
              // Interactions & Duplication Section
              if (warnings.isNotEmpty)
                Container(
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
                                  ? 'พบปฏิกิริยาระหว่างยาหรือข้อห้ามใช้'
                                  : 'Drug interactions or contraindications found',
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
                      ...warnings.map(
                        (w) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '• $w',
                            style: const TextStyle(
                              color: Color(0xFF991B1B),
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (warnings.isEmpty)
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
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: drugs.length,
                  itemBuilder: (context, index) {
                    final d = drugs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.borderDefault),
                      ),
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
                    );
                  },
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
}
