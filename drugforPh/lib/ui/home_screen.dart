import 'package:flutter/material.dart';
import '../data/drug_database.dart';
import '../core/models/models.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';
import 'widgets/patient_banner.dart';
import '../data/prescription_cart.dart';
import 'prescription_cart_screen.dart';
import 'ai_consultant_screen.dart';

class HomeScreen extends StatefulWidget {
  final Locale currentLocale;
  final ValueChanged<Locale> onLocaleChange;

  const HomeScreen({
    super.key,
    required this.currentLocale,
    required this.onLocaleChange,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  DrugCategory? _selectedCategory;
  Drug? _selectedDrugForDesktop; // Track selected drug for desktop view
  final ScrollController _categoryScrollController = ScrollController();

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  bool get isThai => widget.currentLocale.languageCode == 'th';

  Color _getCategoryColor(DrugCategory category) {
    switch (category) {
      case DrugCategory.antibiotic:
        return Colors.teal;
      case DrugCategory.cardiovascular:
      case DrugCategory.vasopressor:
        return Colors.red.shade400;
      case DrugCategory.analgesic:
      case DrugCategory.nsaid:
      case DrugCategory.opioid:
        return Colors.orange;
      case DrugCategory.neurological:
      case DrugCategory.sedative:
        return Colors.deepPurple;
      case DrugCategory.gastrointestinal:
      case DrugCategory.antiemetic:
        return Colors.lightGreen.shade600;
      case DrugCategory.respiratory:
        return Colors.lightBlue;
      case DrugCategory.endocrine:
        return Colors.pink.shade300;
      case DrugCategory.chemotherapy:
        return Colors.brown;
      case DrugCategory.antiInflammatory:
        return Colors.amber.shade700;
      case DrugCategory.antihistamine:
        return Colors.cyan;
      case DrugCategory.supplement:
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(DrugCategory category) {
    switch (category) {
      case DrugCategory.antibiotic:
        return Icons.medication;
      case DrugCategory.cardiovascular:
      case DrugCategory.vasopressor:
        return Icons.favorite;
      case DrugCategory.analgesic:
      case DrugCategory.nsaid:
      case DrugCategory.opioid:
        return Icons.personal_injury;
      case DrugCategory.neurological:
      case DrugCategory.sedative:
        return Icons.psychology;
      case DrugCategory.gastrointestinal:
      case DrugCategory.antiemetic:
        return Icons.spa;
      case DrugCategory.respiratory:
        return Icons.air;
      case DrugCategory.endocrine:
        return Icons.bloodtype;
      case DrugCategory.chemotherapy:
        return Icons.coronavirus;
      case DrugCategory.antiInflammatory:
        return Icons.local_fire_department;
      case DrugCategory.antihistamine:
        return Icons.eco;
      case DrugCategory.supplement:
        return Icons.science;
      default:
        return Icons.healing;
    }
  }

  void _onDrugTapped(BuildContext context, Drug drug, bool isDesktop) {
    if (isDesktop) {
      setState(() {
        _selectedDrugForDesktop = drug;
      });
    } else {
      final catColor = _getCategoryColor(drug.category);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CalculatorScreen(
            drug: drug,
            isThai: isThai,
            categoryColor: catColor,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop =
            constraints.maxWidth > 800; // Breakpoint for PC/Tablet

        Widget drugListWidget = _buildDrugList(isDesktop);

        if (isDesktop) {
          // SPLIT VIEW FOR DESKTOP
          return Scaffold(
            backgroundColor: Colors.grey.shade200,
            body: Column(
              children: [
                PatientBanner(isThai: isThai),
                Expanded(
                  child: Row(
                    children: [
                      // Left Panel: Drug List (Fixed width)
                      Container(
                        width: 380,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(2, 0),
                            )
                          ],
                        ),
                        child: drugListWidget,
                      ),

                      // Right Panel: Calculator
                      Expanded(
                        child: _selectedDrugForDesktop == null
                            ? Container(
                                color: Colors.grey.shade100,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.touch_app,
                                          size: 80,
                                          color: Colors.grey.shade300),
                                      const SizedBox(height: 16),
                                      Text(
                                        isThai
                                            ? 'เลือกยาจากเมนูด้านซ้ายเพื่อเริ่มคำนวณ'
                                            : 'Select a drug from the left to calculate',
                                        style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.grey.shade500),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : CalculatorScreen(
                                // using UniqueKey to force rebuilding state when drug changes on desktop
                                key: ValueKey(_selectedDrugForDesktop!.id),
                                drug: _selectedDrugForDesktop!,
                                isThai: isThai,
                                categoryColor: _getCategoryColor(
                                    _selectedDrugForDesktop!.category),
                              ), // End CalculatorScreen
                      ), // End right panel Expanded
                    ],
                  ), // End Row
                ), // End Row wrapper Expanded
              ],
            ), // End Column
          ); // End Scaffold
        } // End if (isDesktop)

        // MOBILE VIEW (Full Screen List)
        return Scaffold(
          body: Column(
            children: [
              PatientBanner(isThai: isThai),
              Expanded(child: drugListWidget),
            ],
          ),
        );
      },
    );
  }

  // The actual Drug List UI (reused in both Mobile and Left Panel of Desktop)
  Widget _buildDrugList(bool isDesktop) {
    List<Drug> displayDrugs = DrugDatabase.search(_searchQuery);
    if (_selectedCategory != null) {
      displayDrugs =
          displayDrugs.where((d) => d.category == _selectedCategory).toList();
    }
    displayDrugs.sort((a, b) => a.genericName.compareTo(b.genericName));

    final categories = DrugCategory.values.where((c) {
      return DrugDatabase.allDrugs.any((d) => d.category == c);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          isThai ? 'รายชื่อยา' : 'Medications',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          ValueListenableBuilder<List<Drug>>(
            valueListenable: PrescriptionCart.instance.items,
            builder: (context, drugs, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    tooltip: isThai
                        ? 'ตะกร้ายา (เช็กยาตีกัน)'
                        : 'Prescription Cart (DDI)',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PrescriptionCartScreen(isThai: isThai),
                        ),
                      );
                    },
                  ),
                  if (drugs.isNotEmpty)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${drugs.length}',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy),
            tooltip: isThai ? 'AI ผู้ช่วย' : 'AI Assistant',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AiConsultantScreen(isThai: isThai),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: isThai ? 'ประวัติ' : 'History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(isThai: isThai),
                ),
              );
            },
          ),
          TextButton(
            onPressed: () {
              widget.onLocaleChange(
                  isThai ? const Locale('en', 'US') : const Locale('th', 'TH'));
            },
            child: Text(isThai ? 'EN' : 'TH',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Warning Banner
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: Colors.amber.shade200,
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.deepOrange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isThai
                        ? 'ซอฟต์แวร์ต้นแบบ ห้ามใช้กับผู้ป่วยจริง'
                        : 'Prototype. Do NOT use clinically.',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepOrange),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Container(
            color: Colors.teal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: isThai ? 'ค้นหายา...' : 'Search...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Category Filter Cards
          SizedBox(
            height: 95,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.chevron_left, color: Colors.teal.shade700, size: 32),
                  onPressed: () {
                    _categoryScrollController.animateTo(
                      _categoryScrollController.offset - 250,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _categoryScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    itemCount: categories.length + 1,
                    itemBuilder: (context, index) {
                      final isAll = index == 0;
                      final cat = isAll ? null : categories[index - 1];
                      final isSelected = _selectedCategory == cat;
                      
                      // Need to cast to MaterialColor to use .shade400, if not possible we use withOpacity
                      final baseColor = isAll ? Colors.teal : _getCategoryColor(cat!);
                      final Color startColor = baseColor is MaterialColor ? baseColor.shade400 : baseColor;
                      final Color endColor = baseColor is MaterialColor ? baseColor.shade600 : baseColor;
                      
                      final icon = isAll ? Icons.apps : _getCategoryIcon(cat!);
                      final label = isAll ? (isThai ? 'ทั้งหมด' : 'All') : (isThai ? cat!.nameTh : cat!.nameEn);

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [startColor, endColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [Colors.white, Colors.white],
                            ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: baseColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon, color: isSelected ? Colors.white : baseColor, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Colors.teal.shade700, size: 32),
            onPressed: () {
              _categoryScrollController.animateTo(
                _categoryScrollController.offset + 250,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    ),

    // Drug List
          Expanded(
            child: displayDrugs.isEmpty
                ? Center(
                    child: Text(
                      isThai ? 'ไม่พบข้อมูลยา' : 'No drugs found',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 8.0),
                    itemCount: displayDrugs.length,
                    itemBuilder: (context, index) {
                      final drug = displayDrugs[index];
                      final catColor = _getCategoryColor(drug.category);
                      final isSelected =
                          isDesktop && _selectedDrugForDesktop?.id == drug.id;

                      return Card(
                        elevation: isSelected ? 4 : 1,
                        margin: const EdgeInsets.only(bottom: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected
                                ? catColor
                                : (drug.isHighAlert
                                    ? Colors.red.withOpacity(0.5)
                                    : Colors.transparent),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _onDrugTapped(context, drug, isDesktop),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(_getCategoryIcon(drug.category),
                                      color: catColor, size: 24),
                                ),
                                const SizedBox(width: 12),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              drug.genericName,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: isSelected
                                                    ? FontWeight.w900
                                                    : FontWeight.bold,
                                                color: isSelected
                                                    ? catColor
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                          if (drug.isHighAlert)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Text('High Alert',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 9,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        isThai && drug.nameTh != null
                                            ? '${drug.nameTh} • ${drug.brandNames.take(1).join(", ")}'
                                            : drug.brandNames
                                                .take(2)
                                                .join(", "),
                                        style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isDesktop) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right,
                                      color: Colors.grey.shade400, size: 20),
                                ]
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
