import 'ai_consult_screen.dart';
import 'package:flutter/material.dart';
import '../data/drug_database.dart';
import '../core/models/models.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';
import 'widgets/patient_banner.dart';
import '../data/prescription_cart.dart';
import 'prescription_cart_screen.dart';

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
    if (category.name == 'antifungal' || category.name == 'antfungal') {
      return Colors.teal.shade700;
    }

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
      // Antifungal category is handled by name below so this screen
      // remains compatible with either `antifungal` or legacy `antfungal`
      // in DrugCategory.
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(DrugCategory category) {
    if (category.name == 'antifungal' || category.name == 'antfungal') {
      return Icons.bug_report;
    }

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
      // Antifungal category is handled by name below.
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
        final isDesktop = constraints.maxWidth > 800; // Breakpoint for PC/Tablet

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
        actions: [
          // ปุ่มไอคอนปรึกษา AI ที่ฝังไว้ส่วนบนสุดของแอปพลิเคชัน
          IconButton(
            icon: const Icon(Icons.psychology, size: 28),
            tooltip: isThai ? 'ปรึกษา AI' : 'Consult AI',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AiConsultantScreen(isThai: true)),
              );
            },
          ),
          ValueListenableBuilder<List<Drug>>(
            valueListenable: PrescriptionCart.instance.items,
            builder: (context, drugs, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    tooltip: isThai
                        ? 'ตะกร้ายา (เช็คยาดีกัน)'
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
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${drugs.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: isThai ? 'ประวัติการคำนวณ' : 'Calculation History',
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
                isThai ? const Locale('en') : const Locale('th'),
              );
            },
            child: Text(
              isThai ? 'EN' : 'TH',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: isThai ? 'ค้นหายา...' : 'Search drugs...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Categories Horizontal List
          SizedBox(
            height: 55,
            child: ListView.builder(
              controller: _categoryScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = _selectedCategory == null;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(isThai ? 'ทั้งหมด' : 'All'),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = null;
                        });
                      },
                      selectedColor: Colors.teal.shade400,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }

                final category = categories[index - 1];
                final isSelected = _selectedCategory == category;
                final catColor = _getCategoryColor(category);

                String categoryLabel = category.name;
                if (isThai) {
                  if (category.name == 'antifungal' ||
                      category.name == 'antfungal') {
                    categoryLabel = 'ยาฆ่าเชื้อรา';
                  } else {
                    switch (category) {
                    case DrugCategory.antibiotic:
                      categoryLabel = 'ยาปฏิชีวนะ';
                      break;
                    case DrugCategory.cardiovascular:
                      categoryLabel = 'ยาระบบหัวใจ';
                      break;
                    case DrugCategory.analgesic:
                      categoryLabel = 'ยาแก้ปวด';
                      break;
                    case DrugCategory.nsaid:
                      categoryLabel = 'ยาแก้ปวด NSAID';
                      break;
                    case DrugCategory.neurological:
                      categoryLabel = 'ยาระบบประสาท';
                      break;
                    case DrugCategory.gastrointestinal:
                      categoryLabel = 'ยาระบบทางเดินอาหาร';
                      break;
                    case DrugCategory.respiratory:
                      categoryLabel = 'ยาระบบทางเดินหายใจ';
                      break;
                    case DrugCategory.endocrine:
                      categoryLabel = 'ยาระบบต่อมไร้ท่อ';
                      break;
                    case DrugCategory.chemotherapy:
                      categoryLabel = 'ยาเคมีบำบัด';
                      break;
                    case DrugCategory.antiInflammatory:
                      categoryLabel = 'ยาต้านการอักเสบ';
                      break;
                    case DrugCategory.antihistamine:
                      categoryLabel = 'ยาแก้แพ้';
                      break;
                    case DrugCategory.supplement:
                      categoryLabel = 'สารอาหาร/วิตามิน';
                      break;
                    case DrugCategory.vasopressor:
                      categoryLabel = 'ยากระตุ้นความดัน';
                      break;
                    case DrugCategory.sedative:
                      categoryLabel = 'ยานอนหลับ/สงบประสาท';
                      break;
                    case DrugCategory.antiemetic:
                      categoryLabel = 'ยาแก้คลื่นไส้อาเจียน';
                      break;
                    case DrugCategory.opioid:
                      categoryLabel = 'ยาแก้ปวดกลุ่มโอปิออยด์';
                      break;
                    default:
                      break;
                    }
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                  child: FilterChip(
                    avatar: Icon(
                      _getCategoryIcon(category),
                      color: isSelected ? Colors.white : catColor,
                      size: 16,
                    ),
                    selected: isSelected,
                    label: Text(categoryLabel),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : null;
                      });
                    },
                    selectedColor: catColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ),

          // Drug List
          Expanded(
            child: displayDrugs.isEmpty
                ? Center(
                    child: Text(
                      isThai ? 'ไม่พบรายชื่อยา' : 'No drugs found',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : ListView.builder(
                    itemCount: displayDrugs.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, index) {
                      final drug = displayDrugs[index];
                      final isSelectedForDesktop =
                          isDesktop && _selectedDrugForDesktop?.id == drug.id;

                      return Card(
                        color: isSelectedForDesktop
                            ? Colors.blue.shade50
                            : Colors.white,
                        elevation: isSelectedForDesktop ? 3 : 1,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isSelectedForDesktop
                              ? BorderSide(color: Colors.blue.shade400, width: 1.5)
                              : BorderSide.none,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor:
                                _getCategoryColor(drug.category).withOpacity(0.1),
                            child: Icon(
                              _getCategoryIcon(drug.category),
                              color: _getCategoryColor(drug.category),
                            ),
                          ),
                          title: Text(
                            drug.genericName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            drug.genericName,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          trailing: drug.isHighAlert
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: Colors.red.shade300),
                                  ),
                                  child: Text(
                                    isThai ? 'High Alert' : 'High Alert',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => _onDrugTapped(context, drug, isDesktop),
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
