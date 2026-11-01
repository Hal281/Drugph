// ignore_for_file: avoid_print, prefer_const_constructors, unnecessary_string_interpolations

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:drug_dosage_calculator/core/core.dart';
import 'package:drug_dosage_calculator/data/drug_database.dart';

void main() async {
  print('====================================================');
  print('Generating Clinical Pharmacist Dossier PDF...');
  print('====================================================');

  final doc = pw.Document();

  // Load font if available for Thai glyphs
  pw.Font? thaiFont;
  final fontFile = File('assets/fonts/ThaiFont.ttf');
  if (fontFile.existsSync()) {
    final fontBytes = fontFile.readAsBytesSync();
    thaiFont = pw.Font.ttf(fontBytes.buffer.asByteData());
    print('Loaded Thai font: assets/fonts/ThaiFont.ttf');
  } else {
    print('Warning: Thai font not found, falling back to default Helvetica');
  }

  final theme = thaiFont != null
      ? pw.ThemeData.withFont(
          base: thaiFont,
          bold: thaiFont,
          italic: thaiFont,
          boldItalic: thaiFont,
        )
      : pw.ThemeData.base();

  final allDrugs = DrugDatabase.allDrugs;
  final totalRegimens =
      allDrugs.fold<int>(0, (sum, d) => sum + d.regimens.length);

  // 14 Core Hospital High-Alert Medication IDs
  const highAlertIds = [
    'warfarin',
    'heparin',
    'enoxaparin',
    'apixaban',
    'rivaroxaban',
    'norepinephrine',
    'epinephrine',
    'dopamine',
    'dobutamine',
    'nicardipine',
    'amiodarone',
    'insulin_regular',
    'magnesium_sulfate',
    'oxytocin',
  ];

  final highAlertDrugs = <Drug>[];
  for (final id in highAlertIds) {
    final found = allDrugs.where((d) => d.id == id).toList();
    if (found.isNotEmpty) {
      highAlertDrugs.add(found.first);
    }
  }

  final generalDrugs =
      allDrugs.where((d) => !highAlertIds.contains(d.id)).toList();
  const pendingDecisions = PendingPharmacistRegistry.allDecisions;

  final totalMonographs =
      allDrugs.where((d) => d.monograph != null || d.provenance != null).length;
  const verifiedRulesCount = 1; // Apixaban 2-of-3 criteria

  print('Total Drugs: ${allDrugs.length}');
  print('Total Regimens: $totalRegimens');
  print('High-Alert Medications: ${highAlertDrugs.length}');
  print('General Formulary Drugs: ${generalDrugs.length}');
  print('Drugs with Monograph / Provenance: $totalMonographs');
  print('Pending Pharmacist Decisions: ${pendingDecisions.length}');

  // Chunking for strict page budgeting (prevents pw.Page layout overflow)
  final highAlertChunks = <List<Drug>>[];
  const highAlertChunkSize = 2; // 2 detailed cards per page (7 pages)
  for (var i = 0; i < highAlertDrugs.length; i += highAlertChunkSize) {
    highAlertChunks.add(
      highAlertDrugs.sublist(
        i,
        i + highAlertChunkSize > highAlertDrugs.length
            ? highAlertDrugs.length
            : i + highAlertChunkSize,
      ),
    );
  }

  final generalChunks = <List<Drug>>[];
  const generalChunkSize = 3; // 3 drugs per page (35 pages)
  for (var i = 0; i < generalDrugs.length; i += generalChunkSize) {
    generalChunks.add(
      generalDrugs.sublist(
        i,
        i + generalChunkSize > generalDrugs.length
            ? generalDrugs.length
            : i + generalChunkSize,
      ),
    );
  }

  final decisionChunks = <List<PendingClinicalDecision>>[];
  const decisionChunkSize = 2; // 2 decisions per page (3 pages)
  for (var i = 0; i < pendingDecisions.length; i += decisionChunkSize) {
    decisionChunks.add(
      pendingDecisions.sublist(
        i,
        i + decisionChunkSize > pendingDecisions.length
            ? pendingDecisions.length
            : i + decisionChunkSize,
      ),
    );
  }

  final totalPages = 1 +
      highAlertChunks.length +
      generalChunks.length +
      decisionChunks.length +
      1;
  var currentPage = 1;

  // ===========================================================================
  // SECTION 1: Cover / Executive Overview & Protocol (Page 1)
  // ===========================================================================
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#00695C'), // Teal 800
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'DRUGPH — CLINICAL FORMULARY VERIFICATION DOSSIER',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'เอกสารตรวจรับรองความถูกต้องของสูตรคำนวณและขนาดยาทางคลินิก (Clinical Verification Protocol)',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Software as a Medical Device (SaMD) Level II Clinical Evaluation Dossier',
                    style: pw.TextStyle(
                      color: PdfColor.fromHex('#B2DFDB'),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            pw.Text(
              '1. วัตถุประสงค์และระเบียบปฏิบัติ (Purpose & Scope)',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'เอกสารฉบับนี้จัดทำขึ้นเพื่อให้เภสัชกรคลินิก (Clinical Pharmacist) และอาจารย์แพทย์ผู้เชี่ยวชาญ (Attending Physician / PTC Chair) '
              'ตรวจสอบความถูกต้องของสูตรคำนวณ โดสยามาตรฐาน ขนาดยาสูงสุด และเกณฑ์การปรับขนาดยาตามระดับไต (CrCl) ในระบบ Drugph ทุกรายการ '
              'ตามกฎเหล็กข้อที่ 2 (Strict Evidence-Based Medicine) และข้อที่ 1 (Zero-Error Calculation Policy) '
              'ก่อนนำระบบไปใช้งานจริงข้างเตียงผู้ป่วย (Bedside Clinical Decision Support)',
              style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.35),
            ),
            pw.SizedBox(height: 12),

            pw.Text(
              '2. ตำรามาตรฐานทางการแพทย์และเภสัชกรรมที่ใช้เป็นเกณฑ์อ้างอิง (Approved Textbooks)',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal900,
              ),
            ),
            pw.SizedBox(height: 4),
            _buildBullet(
                '1. The Sanford Guide to Antimicrobial Therapy (54th Edition, 2024) — ยาต้านจุลชีพและการปรับตามไต'),
            _buildBullet(
                '2. Lexicomp Drug Information / UpToDate 2024 — ฐานข้อมูลขนาดยาและปฏิกิริยาระหว่างยามาตรฐานสากล'),
            _buildBullet(
                '3. คู่มือการปรับขนาดยาในผู้ป่วยโรคไต โดย สมาคมโรคไตแห่งประเทศไทย (The Nephrology Society of Thailand)'),
            _buildBullet(
                '4. แนวทางการรักษาโรคติดเชื้อในประเทศไทย โดย สมาคมโรคติดเชื้อแห่งประเทศไทย (IDAT Guidelines)'),
            _buildBullet(
                '5. บัญชียาหลักแห่งชาติ (NLEM) และคู่มือการใช้ยาอย่างสมเหตุผล (RDU Thailand โดย อย.)'),
            _buildBullet(
                '6. คู่มือการบริหารยาฉีดสำหรับพยาบาลและเภสัชกร (โรงพยาบาลรามาธิบดี และ โรงพยาบาลศิริราช)'),
            _buildBullet(
                '7. DiPiro\'s Pharmacotherapy: A Pathophysiologic Approach & Goodman & Gilman\'s 14th ed.'),
            _buildBullet(
                '8. Official US FDA Structured Product Labeling (SPL) via openFDA API Database'),
            pw.SizedBox(height: 12),

            pw.Text(
              '3. ข้อมูลสรุปทางสถิติ (Formulary Summary & Review Metrics)',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal900,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox(
                    'จำนวนยาทั้งหมด', '${allDrugs.length} รายการ', 84),
                _buildStatBox('จำนวนสูตรยา', '$totalRegimens สูตร', 84),
                _buildStatBox(
                    'High-Alert Monographs', '${highAlertDrugs.length} รายการ', 84),
                _buildStatBox('Monographs ทั้งหมด', '$totalMonographs รายการ', 84),
                _buildStatBox('กฎที่ตรวจรับรองแล้ว', '$verifiedRulesCount กฎ (Apixaban)', 84),
                _buildStatBox(
                    'ประเด็นรอการตัดสินใจ', '${pendingDecisions.length} ข้อ (DEC-PND)', 84),
              ],
            ),
            pw.SizedBox(height: 14),

            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF8E1'), // Amber 50
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.amber600),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('⚠️ ', style: const pw.TextStyle(fontSize: 11)),
                  pw.Expanded(
                    child: pw.Text(
                      'คำชี้แจงสำหรับผู้ตรวจ: หากพบว่าตัวเลขโดสยา, หน่วยยา, หรือช่วง CrCl ในเอกสารนี้ ไม่ตรงกับตำรามาตรฐานฉบับปัจจุบัน '
                      'กรุณาขีดฆ่าและระบุตัวเลขที่ถูกต้องพร้อมเขียนชื่อตำรา หน้า และปีพิมพ์ในช่องหมายเหตุ '
                      'ห้ามอนุมัติรายการยาที่ไม่มีหลักฐานทางคลินิกรองรับอย่างชัดเจนเด็ดขาด',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        color: PdfColors.brown900,
                        fontWeight: pw.FontWeight.bold,
                        lineSpacing: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            pw.Text(
              'โครงสร้างเอกสาร: หมวด 1 ภาพรวมและสถิติ | หมวด 2 ยาเตือนภัยสูง 14 รายการ (หน้า 2–8) | หมวด 3 รายการยาทั่วไป 103 รายการ (หน้า 9–43) | หมวด 4 ภาคผนวกการตัดสินใจทางคลินิก 6 ข้อ และหนังสือรับรองสถาบัน (หน้า 44–47)',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
            ),
          ],
        );
      },
    ),
  );

  // ===========================================================================
  // SECTION 2: High-Alert Featured Monographs (14 drugs, 2 per page = 7 pages)
  // ===========================================================================
  for (var pageIdx = 0; pageIdx < highAlertChunks.length; pageIdx++) {
    currentPage++;
    final chunk = highAlertChunks[pageIdx];
    final thisPage = currentPage;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'DRUGPH CLINICAL VERIFICATION DOSSIER — หมวดยาเตือนภัยสูง (High-Alert Monographs)',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red900,
                    ),
                  ),
                  pw.Text(
                    'หน้า $thisPage จาก $totalPages',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.red800, thickness: 1),
              pw.SizedBox(height: 4),

              // 2 high-alert drug cards
              ...chunk.map((drug) => _buildHighAlertMonographCard(drug)),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SECTION 3: General Formulary Verification Table (103 drugs, 3 per page)
  // ===========================================================================
  for (var pageIdx = 0; pageIdx < generalChunks.length; pageIdx++) {
    currentPage++;
    final chunk = generalChunks[pageIdx];
    final thisPage = currentPage;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'DRUGPH CLINICAL VERIFICATION DOSSIER — ทะเบียนรายการยาทั่วไป (General Formulary Table)',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal800,
                    ),
                  ),
                  pw.Text(
                    'หน้า $thisPage จาก $totalPages',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.teal700, thickness: 1),
              pw.SizedBox(height: 4),

              ...chunk.map((drug) => _buildDrugVerificationBlock(drug)),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // SECTION 4: Appendix: 6-Item Pending Decisions (6 items, 2 per page = 3 pages)
  // ===========================================================================
  for (var pageIdx = 0; pageIdx < decisionChunks.length; pageIdx++) {
    currentPage++;
    final chunk = decisionChunks[pageIdx];
    final thisPage = currentPage;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'DRUGPH CLINICAL VERIFICATION DOSSIER — ภาคผนวก: การตัดสินใจทางคลินิกที่รอรับรอง (Appendix: Pending Clinical Decisions)',
                    style: pw.TextStyle(
                      fontSize: 8.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#E65100'), // Orange 900
                    ),
                  ),
                  pw.Text(
                    'หน้า $thisPage จาก $totalPages',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Divider(color: PdfColor.fromHex('#E65100'), thickness: 1),
              pw.SizedBox(height: 4),

              // 2 decision cards
              ...chunk.map((dec) => _buildPendingDecisionCard(dec)),
            ],
          );
        },
      ),
    );
  }

  // ===========================================================================
  // FINAL PAGE: Institutional Certification & Signatures (Page 47)
  // ===========================================================================
  currentPage++;
  final finalPageNumber = currentPage;

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'DRUGPH CLINICAL VERIFICATION DOSSIER — หนังสือรับรองการตรวจทางคลินิก',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal800,
                  ),
                ),
                pw.Text(
                  'หน้า $finalPageNumber จาก $totalPages',
                  style:
                      const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.Divider(color: PdfColors.teal700, thickness: 1),
            pw.SizedBox(height: 10),

            pw.Text(
              'หนังสือรับรองความถูกต้องทางคลินิก (Clinical Verification Certification)',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal900,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'ข้าพเจ้าขอรับรองว่าได้ตรวจสอบขนาดยา สูตรการคำนวณ เกณฑ์การปรับยาตามระดับไต และคำเตือนความปลอดภัยทางยา '
              'ในระบบ Drugph เทียบเคียงกับตำรามาตรฐานสากลและแนวทางเวชปฏิบัติของประเทศไทยอย่างละเอียดเรียบร้อยแล้ว '
              'รวมถึงได้พิจารณาข้อบ่งชี้ทางคลินิกในหมวดยาเตือนภัยสูง (High-Alert Medications) และประเด็นการตัดสินใจทางคลินิกในภาคผนวกครบถ้วน',
              style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.35),
            ),
            pw.SizedBox(height: 12),

            // Summary box of audited scope
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#E0F2F1'), // Teal 50
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.teal600),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatBox('Formulary ที่ตรวจรับรอง',
                      '${allDrugs.length} ยา / $totalRegimens สูตร', 150),
                  _buildStatBox('High-Alert Monographs',
                      '${highAlertDrugs.length} รายการ ละเอียด', 150),
                  _buildStatBox('มติการตัดสินใจ PTC',
                      '${pendingDecisions.length} ข้อ ผ่านการพิจารณา', 150),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Pharmacist Box
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.teal700, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '1. เภสัชกรคลินิกผู้ตรวจรับรอง (Clinical Pharmacist Reviewer)',
                        style: pw.TextStyle(
                          fontSize: 10.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900,
                        ),
                      ),
                      pw.Text(
                        '[  ] ตรวจผ่านทุกรายการ  [  ] มีรายการแก้ไข',
                        style: const pw.TextStyle(
                            fontSize: 8.5, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 14),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                            'ลงชื่อ: _________________________________________',
                            style: const pw.TextStyle(fontSize: 9.5)),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                            '( ภก./ภญ. ___________________________________ )',
                            style: const pw.TextStyle(fontSize: 9.5)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                            'เลขที่ใบประกอบวิชาชีพเภสัชกรรม: ภ. _______________',
                            style: const pw.TextStyle(fontSize: 9.5)),
                      ),
                      pw.Expanded(
                        child: pw.Text('วันที่: _____ / _____ / ________',
                            style: const pw.TextStyle(fontSize: 9.5)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                      'ตำแหน่ง / แผนก: ____________________________________________________________________',
                      style: const pw.TextStyle(
                          fontSize: 8.5, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Attending Physician / Chair Box
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.teal700, width: 1.5),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '2. อาจารย์แพทย์ / ประธานคณะกรรมการ PTC ผู้ตรวจอนุมัติ (Attending Physician / PTC Chair)',
                        style: pw.TextStyle(
                          fontSize: 10.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900,
                        ),
                      ),
                      pw.Text(
                        '[  ] อนุมัติใช้งานทางคลินิก',
                        style: const pw.TextStyle(
                            fontSize: 8.5, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 14),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                            'ลงชื่อ: _________________________________________',
                            style: const pw.TextStyle(fontSize: 9.5)),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                            '( นพ./พญ./ศ./ผศ. _____________________________ )',
                            style: const pw.TextStyle(fontSize: 9.5)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                            'เลขที่ใบประกอบวิชาชีพเวชกรรม: ว. _______________',
                            style: const pw.TextStyle(fontSize: 9.5)),
                      ),
                      pw.Expanded(
                        child: pw.Text('วันที่: _____ / _____ / ________',
                            style: const pw.TextStyle(fontSize: 9.5)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                      'ตำแหน่ง / สถาบัน: ____________________________________________________________________',
                      style: const pw.TextStyle(
                          fontSize: 8.5, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Footer note
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'หมายเหตุ: เมื่อลงลายมือชื่อรับรองครบถ้วนแล้ว ให้สแกนเอกสารฉบับนี้จัดเก็บในระบบเพื่อเป็นบันทึกการตรวจสอบคุณภาพ (Audit Trail) '
                'และบันทึกชื่อผู้ตรวจ เลขที่ใบอนุญาต และวันที่ลงในฟิลด์ Provenance ของซอร์สโค้ดตามระเบียบ docs/VERIFICATION_PROTOCOL.md',
                style: const pw.TextStyle(
                    fontSize: 7.5, color: PdfColors.grey800, lineSpacing: 1.3),
              ),
            ),
          ],
        );
      },
    ),
  );

  // Write PDF to disk
  final outputDir = Directory('review');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outputFile = File('review/Clinical_Verification_Dossier.pdf');
  await outputFile.writeAsBytes(await doc.save());

  print('====================================================');
  print('✅ Successfully generated PDF: ${outputFile.path}');
  print('Size: ${(outputFile.lengthSync() / 1024).toStringAsFixed(1)} KB');
  print('Pages: $totalPages');
  print('====================================================');
}

pw.Widget _buildBullet(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2.5, left: 6),
    child: pw.Text(
      text,
      style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
    ),
  );
}

pw.Widget _buildStatBox(String title, String value, [double width = 110]) {
  return pw.Container(
    width: width,
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#F1F5F9'),
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Column(
      children: [
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal900,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    ),
  );
}

// =============================================================================
// Section 2 Helper: Detailed High-Alert Monograph Card
// =============================================================================
pw.Widget _buildHighAlertMonographCard(Drug drug) {
  final mono = drug.monograph;
  final isSignedOff = drug.provenance?.reviewerLicense != null &&
      drug.provenance!.reviewerLicense!.trim().isNotEmpty;

  final citation = mono != null
      ? '${mono.textbookName} (${mono.editionYear}) — ${mono.sectionOrTable ?? ""}'
      : drug.sourceCitation;

  final badges = <String>['HIGH-ALERT'];
  if (drug.requiresTDM) badges.add('TDM');
  if (drug.requiresRenalAdjustment) badges.add('RENAL-ADJ');
  if (drug.requiresHepaticCaution) badges.add('HEPATIC');

  final dosingText = mono?.dosingGuideline ??
      (drug.regimens.isNotEmpty
          ? drug.regimens.map((r) => '• ${r.indication}: ${r.dosingType.nameEn}').join('\n')
          : 'ไม่มีข้อมูลขนาดยา');

  final renalText = mono?.renalGuideline ??
      (drug.requiresRenalAdjustment
          ? 'ต้องปรับขนาดยาตามระดับไต (ดูตารางสูตรยา)'
          : 'ไม่จำเป็นต้องปรับขนาดยาตามระดับไต');

  final adminText = mono?.administrationGuideline ?? 'ให้ยาตามข้อกำหนดของแพทย์และคู่มือยาฉีด';
  final notesText = mono?.clinicalNotes ??
      (drug.contraindications.isNotEmpty
          ? 'ข้อห้ามใช้: ${drug.contraindications.join(", ")}'
          : 'ติดตามอาการทางคลินิกอย่างใกล้ชิด');

  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.all(7),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#FFFAFA'),
      border: pw.Border.all(color: PdfColors.red300, width: 0.8),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Title & Badges
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text(
                    drug.genericName,
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900,
                    ),
                  ),
                  if (drug.nameTh != null && drug.nameTh!.isNotEmpty) ...[
                    pw.Text(' (${drug.nameTh})',
                        style: const pw.TextStyle(
                            fontSize: 8.5, color: PdfColors.grey800)),
                  ],
                  if (drug.drugClass != null) ...[
                    pw.SizedBox(width: 4),
                    pw.Text('[${drug.drugClass!.name}]',
                        style: const pw.TextStyle(
                            fontSize: 7, color: PdfColors.grey600)),
                  ],
                ],
              ),
            ),
            pw.Row(
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1.5),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red800,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    badges.join(' | '),
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.SizedBox(width: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1.5),
                  decoration: pw.BoxDecoration(
                    color: isSignedOff ? PdfColors.green700 : PdfColors.orange700,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    isSignedOff ? 'VERIFIED' : 'PENDING REVIEW',
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 2),

        // Citation row
        pw.Text(
          'แหล่งอ้างอิง: $citation',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.blueGrey800),
        ),
        pw.SizedBox(height: 3),

        // Dosing Guideline
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ขนาดยาและการบริหารยาตามตำรา (Dosing Guideline):',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.teal900,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                dosingText,
                style: const pw.TextStyle(fontSize: 6.5, lineSpacing: 1.15),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),

        // 2-Column: Renal and Administration
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'การปรับยาตามระดับไต (Renal Impairment):',
                      style: pw.TextStyle(
                        fontSize: 6.8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      renalText,
                      style: const pw.TextStyle(fontSize: 6.2, lineSpacing: 1.1),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(3),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'การบริหารยาและผสมยาฉีด (Administration & IV Dilution):',
                      style: pw.TextStyle(
                        fontSize: 6.8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal800,
                      ),
                    ),
                    pw.SizedBox(height: 1),
                    pw.Text(
                      adminText,
                      style: const pw.TextStyle(fontSize: 6.2, lineSpacing: 1.1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),

        // Clinical Safety & Boxed Warnings
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#FFF5F5'),
            border: pw.Border.all(color: PdfColors.red200, width: 0.5),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'คำเตือนความปลอดภัยทางคลินิก (Clinical Notes & Boxed Warnings):',
                style: pw.TextStyle(
                  fontSize: 6.8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red900,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                notesText,
                style: const pw.TextStyle(
                  fontSize: 6.2,
                  color: PdfColors.brown900,
                  lineSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),

        // Reviewer sign-off row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '[  ] โดสถูกต้องตามตำรา    [  ] การบริหารยา/ไตถูกต้อง    [  ] ทักท้วง: ______________________',
              style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey800),
            ),
            pw.Text(
              'ลงชื่อ: ______________ วันที่: ___/___/___',
              style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey800),
            ),
          ],
        ),
      ],
    ),
  );
}

// =============================================================================
// Section 3 Helper: Compact General Formulary Block (3 drugs per page)
// =============================================================================
pw.Widget _buildDrugVerificationBlock(Drug drug) {
  final isSignedOff = drug.provenance?.reviewerLicense != null &&
      drug.provenance!.reviewerLicense!.trim().isNotEmpty;
  final citation = drug.sourceCitation.isNotEmpty
      ? drug.sourceCitation
      : (drug.monograph?.textbookName ?? 'UNVERIFIED (รอยืนยัน)');
  final badges = <String>[];
  if (drug.isHighAlert) badges.add('HIGH-ALERT');
  if (drug.requiresTDM) badges.add('TDM');
  if (drug.requiresRenalAdjustment) badges.add('RENAL-ADJ');
  if (drug.requiresHepaticCaution) badges.add('HEPATIC');

  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    padding: const pw.EdgeInsets.all(7),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Drug title row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Row(
                children: [
                  pw.Text(
                    drug.genericName,
                    style: pw.TextStyle(
                      fontSize: 9.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900,
                    ),
                  ),
                  if (drug.nameTh != null && drug.nameTh!.isNotEmpty) ...[
                    pw.Text(' (${drug.nameTh})',
                        style: const pw.TextStyle(
                            fontSize: 8.5, color: PdfColors.grey800)),
                  ],
                ],
              ),
            ),
            if (badges.isNotEmpty)
              pw.Text(
                badges.join(' | '),
                style: pw.TextStyle(
                  fontSize: 6.8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red800,
                ),
              ),
          ],
        ),
        pw.SizedBox(height: 2),

        // Citation row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                'แหล่งอ้างอิง: $citation',
                style: const pw.TextStyle(
                    fontSize: 7.2, color: PdfColors.blueGrey800),
              ),
            ),
            pw.Text(
              isSignedOff ? 'Status: VERIFIED' : 'Status: PENDING REVIEW',
              style: pw.TextStyle(
                fontSize: 7.2,
                fontWeight: pw.FontWeight.bold,
                color: isSignedOff ? PdfColors.green800 : PdfColors.orange800,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),

        // Regimens table
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                _buildTableCell('ข้อบ่งใช้ / วิธีให้', isHeader: true, flex: 3),
                _buildTableCell('สูตรขนาดยา', isHeader: true, flex: 3),
                _buildTableCell('ขนาดยาสูงสุด', isHeader: true, flex: 2),
                _buildTableCell('เกณฑ์ปรับตามไต (CrCl)',
                    isHeader: true, flex: 4),
              ],
            ),
            ...drug.regimens.map((r) {
              final renalStr = r.renalAdjustments != null &&
                      r.renalAdjustments!.isNotEmpty
                  ? r.renalAdjustments!
                      .map((ra) =>
                          'CrCl ${ra.crclMin.toInt()}-${ra.crclMax.toInt()}: ${ra.absoluteDose != null ? "${ra.absoluteDose} ${r.doseUnit.symbol}" : "x${ra.adjustmentFactor}"} ${ra.adjustedFrequency?.displayEn ?? ''}')
                      .join('\n')
                  : (drug.requiresRenalAdjustment
                      ? 'ปรับตามดุลยพินิจ'
                      : 'ไม่ต้องปรับ');

              final formulaStr = r.fixedDose != null
                  ? '${r.fixedDose} ${r.doseUnit.symbol} ${r.frequency.displayEn}'
                  : (r.dosePerKg != null
                      ? '${r.dosePerKg} ${r.doseUnit.symbol}/kg ${r.frequency.displayEn}'
                      : (r.continuousRateMin != null
                          ? '${r.continuousRateMin}-${r.continuousRateMax} ${r.continuousRateUnit}'
                          : '${r.dosingType.nameEn}'));

              final limitStr = r.limits?.maxSingleDose != null
                  ? 'Max: ${r.limits!.maxSingleDose} ${r.doseUnit.symbol}'
                  : (r.limits?.maxDailyDose != null
                      ? 'Daily: ${r.limits!.maxDailyDose} ${r.doseUnit.symbol}'
                      : '-');

              return pw.TableRow(
                children: [
                  _buildTableCell(
                      '${r.indication ?? 'ขนาดยาทั่วไป'}\n[${r.route.nameEn}]',
                      flex: 3),
                  _buildTableCell(formulaStr, flex: 3),
                  _buildTableCell(limitStr, flex: 2),
                  _buildTableCell(renalStr, flex: 4),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 3),

        // Pharmacist sign-off checklist row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '[  ] โดสถูกต้องตามตำรา     [  ] ตารางไตถูกต้อง     [  ] มีข้อทักท้วง: _______________________',
              style:
                  const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey800),
            ),
            pw.Text(
              'ลงชื่อผู้ตรวจ: ___________',
              style:
                  const pw.TextStyle(fontSize: 7.2, color: PdfColors.grey800),
            ),
          ],
        ),
      ],
    ),
  );
}

// =============================================================================
// Section 4 Helper: Pending Decision Card (2 items per page)
// =============================================================================
pw.Widget _buildPendingDecisionCard(PendingClinicalDecision dec) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.all(7),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#FFFDF9'),
      border: pw.Border.all(color: PdfColors.orange300, width: 0.8),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Decision Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '[${dec.id}] ${dec.titleEn}',
                    style: pw.TextStyle(
                      fontSize: 8.8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal900,
                    ),
                  ),
                  pw.Text(
                    dec.titleTh,
                    style: const pw.TextStyle(
                        fontSize: 7.8, color: PdfColors.grey800),
                  ),
                ],
              ),
            ),
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF3E0'),
                border: pw.Border.all(color: PdfColors.orange400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                dec.category.titleEn,
                style: pw.TextStyle(
                  fontSize: 6.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#E65100'),
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 2),

        // Scope
        pw.Text(
          'ไฟล์เป้าหมาย: ${dec.targetFile}  |  ตัวยาที่เกี่ยวข้อง: ${dec.affectedDrugIds.join(", ")}',
          style: const pw.TextStyle(fontSize: 6.8, color: PdfColors.blueGrey800),
        ),
        pw.SizedBox(height: 3),

        // Dilemma & Baseline
        pw.Container(
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.grey200, width: 0.5),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ข้อจำกัดทางคลินิก (Clinical Dilemma):',
                style: pw.TextStyle(
                  fontSize: 6.8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.brown900,
                ),
              ),
              pw.Text(
                dec.clinicalDilemmaEn,
                style: const pw.TextStyle(fontSize: 6.2, lineSpacing: 1.1),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'พฤติกรรมการคำนวณปัจจุบัน (Current Baseline Behavior):',
                style: pw.TextStyle(
                  fontSize: 6.8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              pw.Text(
                dec.currentBaselineBehaviorEn,
                style: const pw.TextStyle(
                  fontSize: 6.2,
                  color: PdfColors.blueGrey800,
                  lineSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 3),

        // Candidate Options
        pw.Text(
          'ทางเลือกทางคลินิกที่นำเสนอ (Selectable Candidate Options):',
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal900,
          ),
        ),
        pw.SizedBox(height: 1),

        ...dec.candidateOptions.map((opt) {
          final isDefault = opt.id == dec.defaultOptionId;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 2),
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: pw.BoxDecoration(
              color: isDefault ? PdfColor.fromHex('#F1F8E9') : PdfColors.white,
              border: pw.Border.all(
                color: isDefault ? PdfColors.green400 : PdfColors.grey200,
                width: 0.5,
              ),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('[  ] ',
                    style: pw.TextStyle(
                        fontSize: 7, fontWeight: pw.FontWeight.bold)),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${opt.id.toUpperCase()}: ${opt.titleEn}',
                        style: pw.TextStyle(
                          fontSize: 6.6,
                          fontWeight: pw.FontWeight.bold,
                          color: isDefault
                              ? PdfColors.green900
                              : PdfColors.black,
                        ),
                      ),
                      pw.Text(
                        '${opt.descriptionEn} — อ้างอิง: ${opt.citation}',
                        style: const pw.TextStyle(
                          fontSize: 5.8,
                          color: PdfColors.grey700,
                          lineSpacing: 1.05,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        pw.SizedBox(height: 2),

        // Determination row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'มติที่ประชุม: [  ] Option A    [  ] Option B    [  ] Option C    [  ] อื่นๆ: ________________',
              style:
                  const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey800),
            ),
            pw.Text(
              'ลงชื่อ: ______________ วันที่: ___/___/___',
              style:
                  const pw.TextStyle(fontSize: 6.8, color: PdfColors.grey800),
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _buildTableCell(String text, {bool isHeader = false, int flex = 1}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(3),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 6.8,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: isHeader ? PdfColors.teal900 : PdfColors.black,
      ),
    ),
  );
}
