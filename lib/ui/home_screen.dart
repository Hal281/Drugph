import 'package:flutter/material.dart';
import '../data/drug_database.dart';
import '../data/drug_search_engine.dart';
import '../core/models/models.dart';
import 'calculator_screen.dart';
import 'history_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/patient_banner.dart';
import 'widgets/clinical_search_bar.dart';
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
  final List<String> _recentSearches = [];
  DrugCategory? _selectedCategory;
  Drug? _selectedDrugForDesktop; // Track selected drug for desktop view
  final ScrollController _categoryScrollController = ScrollController();

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      final trimmed = query.trim();
      if (trimmed.isNotEmpty) {
        _recentSearches.remove(trimmed);
        _recentSearches.insert(0, trimmed);
        if (_recentSearches.length > 5) {
          _recentSearches.removeLast();
        }
      }
    });
  }

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  bool get isThai => widget.currentLocale.languageCode == 'th';

  IconData _getCategoryIcon(DrugCategory category) {
    switch (category) {
      case DrugCategory.antibiotic:
        return Icons.medication_outlined;
      case DrugCategory.antifungal:
        return Icons.biotech_outlined;
      case DrugCategory.antiviral:
        return Icons.coronavirus_outlined;
      case DrugCategory.cardiovascular:
      case DrugCategory.vasopressor:
        return Icons.monitor_heart_outlined;
      case DrugCategory.analgesic:
      case DrugCategory.nsaid:
      case DrugCategory.opioid:
        return Icons.healing_outlined;
      case DrugCategory.neurological:
      case DrugCategory.sedative:
        return Icons.psychology_outlined;
      case DrugCategory.gastrointestinal:
      case DrugCategory.antiemetic:
        return Icons.medical_services_outlined;
      case DrugCategory.respiratory:
        return Icons.air_outlined;
      case DrugCategory.endocrine:
        return Icons.bloodtype_outlined;
      case DrugCategory.chemotherapy:
        return Icons.science_outlined;
      case DrugCategory.antiInflammatory:
        return Icons.local_pharmacy_outlined;
      case DrugCategory.antihistamine:
        return Icons.eco_outlined;
      case DrugCategory.supplement:
        return Icons.science_outlined;
      case DrugCategory.antidote:
        return Icons.shield_outlined;
      default:
        return Icons.medication_outlined;
    }
  }

  String _getDrugClassLabel(Drug drug) {
    final drugClass = drug.effectiveDrugClass;
    return isThai
        ? drugClass?.nameTh ?? drug.category.nameTh
        : drugClass?.nameEn ?? drug.category.nameEn;
  }

  void _onDrugTapped(BuildContext context, Drug drug, bool isDesktop) {
    if (isDesktop) {
      setState(() {
        _selectedDrugForDesktop = drug;
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CalculatorScreen(
            drug: drug,
            isThai: isThai,
            categoryColor: AppTheme.primaryTeal,
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

        final Widget drugListWidget = _buildDrugList(isDesktop);

        if (isDesktop) {
          // 2-PANE CLINICAL WORKSPACE FOR DESKTOP / TABLET
          return Scaffold(
            backgroundColor: AppTheme.surfaceBackground,
            body: Column(
              children: [
                PatientBanner(isThai: isThai),
                Expanded(
                  child: Row(
                    children: [
                      // Left Panel: Drug List (Fixed width, clean hairline divider)
                      Container(
                        width: 380,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: AppTheme.borderDefault),
                          ),
                        ),
                        child: drugListWidget,
                      ),

                      // Right Panel: Calculator
                      Expanded(
                        child: _selectedDrugForDesktop == null
                            ? Container(
                                color: AppTheme.surfaceBackground,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryTealSoft,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            border: Border.all(
                                              color: AppTheme.primaryTealBorder,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.calculate_outlined,
                                            size: 32,
                                            color: AppTheme.primaryTeal,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          isThai
                                              ? 'เลือกยาจากรายการด้านซ้ายเพื่อคำนวณขนาดยา'
                                              : 'Select a medication from the left to calculate dose',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.inkPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          isThai
                                              ? 'รองรับการปรับขนาดยาตามการทำงานของไต ตับ และ RRT'
                                              : 'Supports real-time renal, hepatic, and RRT dose adjustment',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            color: AppTheme.inkSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : CalculatorScreen(
                                key: ValueKey(_selectedDrugForDesktop!.id),
                                drug: _selectedDrugForDesktop!,
                                isThai: isThai,
                                categoryColor: AppTheme.primaryTeal,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // MOBILE VIEW (Full Screen List)
        return Scaffold(
          backgroundColor: AppTheme.surfaceBackground,
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
    final List<DrugSearchResult> searchResults =
        DrugDatabase.searchDetailed(_searchQuery);
    var filteredResults = searchResults;
    if (_selectedCategory != null) {
      filteredResults = filteredResults.where((r) {
        if (_selectedCategory == DrugCategory.analgesic) {
          return r.drug.category == DrugCategory.analgesic ||
              r.drug.category == DrugCategory.nsaid ||
              r.drug.category == DrugCategory.opioid;
        }
        return r.drug.category == _selectedCategory;
      }).toList();
    }
    if (_searchQuery.trim().isEmpty) {
      filteredResults = List.of(filteredResults)
        ..sort((a, b) => a.drug.genericName.compareTo(b.drug.genericName));
    }

    final categories = DrugCategory.values.where((c) {
      return DrugDatabase.allDrugs.any((d) => d.category == c);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceBackground,
      appBar: AppBar(
        title: Text(
          isThai ? 'รายชื่อยา' : 'Medications',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          ValueListenableBuilder<List<Drug>>(
            valueListenable: PrescriptionCart.instance.items,
            builder: (context, drugs, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PrescriptionCartScreen(isThai: isThai),
                      ),
                    );
                  },
                  child: Tooltip(
                    message: isThai
                        ? 'ใบสั่งยา / ตรวจยาตีกัน (DDI)'
                        : 'Prescription Cart & DDI Check',
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: drugs.isNotEmpty
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.medication_liquid_outlined,
                            size: 17,
                            color: drugs.isNotEmpty
                                ? AppTheme.primaryTeal
                                : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            drugs.isNotEmpty
                                ? 'DDI (${drugs.length})'
                                : 'DDI',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: drugs.isNotEmpty
                                  ? AppTheme.primaryTeal
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.smart_toy_outlined, size: 21),
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
            icon: const Icon(Icons.history, size: 21),
            tooltip: isThai ? 'ประวัติการคำนวณ' : 'History',
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
            style: TextButton.styleFrom(
              minimumSize: const Size(44, 48),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () {
              widget.onLocaleChange(
                isThai ? const Locale('en', 'US') : const Locale('th', 'TH'),
              );
            },
            child: Text(
              isThai ? 'EN' : 'TH',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Clean Clinical Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ClinicalSearchBar(
              query: _searchQuery,
              isThai: isThai,
              recentQueries: _recentSearches,
              onQueryChanged: _updateSearchQuery,
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              onRecentQuerySelected: (q) {
                _updateSearchQuery(q);
              },
              onClearHistory: () {
                setState(() {
                  _recentSearches.clear();
                });
              },
            ),
          ),

          // Slim 48px Clinical Category Filter Chip Bar
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderDefault),
              ),
            ),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_left,
                      color: AppTheme.inkSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 48,
                    ),
                    onPressed: () {
                      _categoryScrollController.animateTo(
                        _categoryScrollController.offset - 220,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _categoryScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      itemCount: categories.length + 1,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final cat = isAll ? null : categories[index - 1];
                        final isSelected = _selectedCategory == cat;

                        final icon =
                            isAll ? Icons.apps_outlined : _getCategoryIcon(cat!);
                        final label = isAll
                            ? (isThai ? 'ทั้งหมด' : 'All')
                            : (isThai ? cat!.nameTh : cat!.nameEn);

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => setState(() => _selectedCategory = cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryTeal
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryTeal
                                      : AppTheme.borderStrong,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    icon,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.inkSecondary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : AppTheme.inkPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.chevron_right,
                      color: AppTheme.inkSecondary,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 48,
                    ),
                    onPressed: () {
                      _categoryScrollController.animateTo(
                        _categoryScrollController.offset + 220,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Drug List
          Expanded(
            child: filteredResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.search_off_outlined,
                          size: 40,
                          color: AppTheme.inkMuted,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isThai ? 'ไม่พบข้อมูลยาที่ค้นหา' : 'No medications found',
                          style: const TextStyle(
                            color: AppTheme.inkSecondary,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 10.0,
                    ),
                    itemCount: filteredResults.length,
                    itemBuilder: (context, index) {
                      final result = filteredResults[index];
                      final drug = result.drug;
                      final isSelected =
                          isDesktop && _selectedDrugForDesktop?.id == drug.id;
                      final drugClassLabel = _getDrugClassLabel(drug);

                      return Semantics(
                        label:
                            '${drug.genericName}, ${isThai ? drug.category.nameTh : drug.category.nameEn}${drug.isHighAlert ? (isThai ? ", ยาความเสี่ยงสูง" : ", High Alert") : ""}',
                        button: true,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryTealSoft
                                : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryTeal
                                  : (drug.isHighAlert
                                      ? AppTheme.statusCriticalBorder
                                      : AppTheme.borderDefault),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () =>
                                  _onDrugTapped(context, drug, isDesktop),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 10.0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primaryTeal
                                            : AppTheme.surfaceSubtle,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(drug.category),
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.primaryTeal,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Wrap(
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  spacing: 4,
                                                  children: [
                                                    ClinicalHighlightText(
                                                      text: drug.genericName,
                                                      query: _searchQuery,
                                                      style: TextStyle(
                                                        fontSize: 14.5,
                                                        fontWeight: isSelected
                                                            ? FontWeight.w700
                                                            : FontWeight.w600,
                                                        color: isSelected
                                                            ? AppTheme
                                                                .primaryTealDark
                                                            : AppTheme
                                                                .inkPrimary,
                                                      ),
                                                    ),
                                                    Text(
                                                      '($drugClassLabel)',
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: AppTheme
                                                            .inkSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (drug.isHighAlert) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme
                                                        .statusCriticalBg,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                    border: Border.all(
                                                      color: AppTheme
                                                          .statusCriticalBorder,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    isThai
                                                        ? 'ยาความเสี่ยงสูง'
                                                        : 'High Alert',
                                                    style: const TextStyle(
                                                      color: AppTheme
                                                          .statusCritical,
                                                      fontSize: 10.5,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if ((drug.nameTh != null &&
                                                  drug.nameTh!.isNotEmpty) ||
                                              drug.brandNames.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              [
                                                if (drug.nameTh != null &&
                                                    drug.nameTh!.isNotEmpty)
                                                  drug.nameTh!,
                                                if (drug.brandNames.isNotEmpty)
                                                  drug.brandNames
                                                      .take(2)
                                                      .join(', '),
                                              ].join(' • '),
                                              style: const TextStyle(
                                                color: AppTheme.inkSecondary,
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                          if (_searchQuery.trim().isNotEmpty &&
                                              result.matchedReasons.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryTealSoft,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: AppTheme
                                                      .primaryTealBorder,
                                                ),
                                              ),
                                              child: Text(
                                                isThai
                                                    ? result.primaryReasonTh
                                                    : result.primaryReason,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppTheme.primaryTealDark,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (!isDesktop) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.chevron_right,
                                        color: AppTheme.inkMuted,
                                        size: 20,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Compact 1-line clinical disclaimer footer
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceSubtle,
              border: Border(
                top: BorderSide(color: AppTheme.borderDefault),
              ),
            ),
            child: Text(
              isThai
                  ? 'ซอฟต์แวร์ต้นแบบเพื่อการศึกษา (Educational Prototype) — ใช้ประกอบการตัดสินใจทางคลินิกเท่านั้น'
                  : 'Educational SaMD Prototype — Clinical decision support reference only.',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.inkMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
