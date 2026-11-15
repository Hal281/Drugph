import 'package:flutter/material.dart';
import '../data/prescription_cart.dart';
import '../core/models/drug.dart';

class PrescriptionCartScreen extends StatelessWidget {
  final bool isThai;

  const PrescriptionCartScreen({super.key, required this.isThai});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isThai ? 'ตรวจสอบรายการยา' : 'Prescription Cart'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<Drug>>(
        valueListenable: PrescriptionCart.instance.items,
        builder: (context, drugs, child) {
          if (drugs.isEmpty) {
            return Center(
              child: Text(
                isThai ? 'ไม่มีรายการยาในตะกร้า' : 'Cart is empty',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final warnings = PrescriptionCart.instance.checkInteractions(isThai);

          return Column(
            children: [
              // Interactions Section
              if (warnings.isNotEmpty)
                Container(
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            isThai
                                ? 'พบปฏิกิริยาระหว่างยาหรือข้อห้ามใช้'
                                : 'Drug interactions or contraindications found',
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 15.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...warnings.map((w) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(w,
                                style:
                                    const TextStyle(color: Colors.redAccent)),
                          )),
                    ],
                  ),
                ),
              if (warnings.isEmpty)
                Container(
                  color: Colors.green.shade50,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        isThai
                            ? 'ไม่พบปฏิกิริยาระหว่างยาที่รุนแรง'
                            : 'No severe drug interactions found.',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

              // Drug List
              Expanded(
                child: ListView.builder(
                  itemCount: drugs.length,
                  itemBuilder: (context, index) {
                    final d = drugs[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        child:
                            const Icon(Icons.medication, color: Colors.indigo),
                      ),
                      title: Text(d.genericName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(d.brandNames.join(', ')),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () {
                          PrescriptionCart.instance.removeDrug(d.id);
                        },
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {
              PrescriptionCart.instance.clearCart();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(
                        isThai ? 'ล้างรายการยาแล้ว' : 'Cart cleared')),
              );
            },
            child: Text(isThai ? 'ล้างรายการทั้งหมด' : 'Clear Cart'),
          ),
        ),
      ),
    );
  }
}
