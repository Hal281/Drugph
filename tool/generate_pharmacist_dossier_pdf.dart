// ignore_for_file: avoid_print, prefer_const_constructors, unnecessary_string_interpolations

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:drug_dosage_calculator/core/models/models.dart';
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
  final totalRegimens = allDrugs.fold<int>(0, (sum, d) => sum + d.regimens.length);
  final verifiedCount = allDrugs.where((d) => d.provenance != null).length;

  print('Total Drugs: ${allDrugs.length}');
  print('Total Regimens: $totalRegimens');
  print('Drugs with Monograph / Provenance: $verifiedCount');

  // Page 1: Cover / Executive Overview & Protocol
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
            pw.SizedBox(height: 20),

            pw.Text(
              '1. วัตถุประสงค์และระเบียบปฏิบัติ (Purpose & Scope)',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'เอกสารฉบับนี้จัดทำขึ้นเพื่อให้เภสัชกรคลินิก (Clinical Pharmacist) และอาจารย์แพทย์ผู้เชี่ยวชาญ (Attending Physician / Faculty) '
              'ตรวจสอบความถูกต้องของสูตรคำนวณ โดสยามาตรฐาน และเกณฑ์การปรับขนาดยาตามระดับไต (CrCl) ในระบบ Drugph ทุกรายการ '
              'ตามกฎเหล็กข้อที่ 2 (Strict Evidence-Based Medicine) และข้อที่ 1 (Zero-Error Calculation Policy) '
              'ก่อนนำระบบไปใช้งานจริงข้างเตียงผู้ป่วย (Bedside Clinical Decision Support)',
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4),
            ),
            pw.SizedBox(height: 14),

            pw.Text(
              '2. ตำรามาตรฐานทางการแพทย์และเภสัชกรรมที่ใช้เป็นเกณฑ์อ้างอิง (Approved Textbooks)',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
            ),
            pw.SizedBox(height: 6),
            _buildBullet('1. The Sanford Guide to Antimicrobial Therapy (54th Edition, 2024) — ยาต้านจุลชีพและการปรับตามไต'),
            _buildBullet('2. Lexicomp Drug Information / UpToDate 2024 — ฐานข้อมูลขนาดยาและปฏิกิริยาระหว่างยามาตรฐานสากล'),
            _buildBullet('3. คู่มือการปรับขนาดยาในผู้ป่วยโรคไต โดย สมาคมโรคไตแห่งประเทศไทย (The Nephrology Society of Thailand)'),
            _buildBullet('4. แนวทางการรักษาโรคติดเชื้อในประเทศไทย โดย สมาคมโรคติดเชื้อแห่งประเทศไทย (IDAT Guidelines)'),
            _buildBullet('5. บัญชียาหลักแห่งชาติ (NLEM) และคู่มือการใช้ยาอย่างสมเหตุผล (RDU Thailand โดย อย.)'),
            _buildBullet('6. คู่มือการบริหารยาฉีดสำหรับพยาบาลและเภสัชกร (โรงพยาบาลรามาธิบดี และ โรงพยาบาลศิริราช)'),
            _buildBullet('7. DiPiro\'s Pharmacotherapy: A Pathophysiologic Approach & Goodman & Gilman\'s'),
            pw.SizedBox(height: 14),

            pw.Text(
              '3. ข้อมูลสรุปทางสถิติ (Formulary Summary)',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
            ),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox('จำนวนยาทั้งหมดในระบบ', '${allDrugs.length} รายการ'),
                _buildStatBox('จำนวนสูตรยา (Regimens)', '$totalRegimens สูตร'),
                _buildStatBox('ยาที่มี Monograph รับรองแล้ว', '$verifiedCount รายการ'),
                _buildStatBox('สถานะการตรวจ', 'รอลงนามรับรอง (UNVERIFIED)'),
              ],
            ),
            pw.SizedBox(height: 24),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FFF8E1'), // Amber 50
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.amber600),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('⚠️ ', style: const pw.TextStyle(fontSize: 12)),
                  pw.Expanded(
                    child: pw.Text(
                      'คำชี้แจงสำหรับผู้ตรวจ: หากพบว่าตัวเลขโดสยา, หน่วยยา, หรือช่วง CrCl ในเอกสารนี้ ไม่ตรงกับตำรามาตรฐานฉบับปัจจุบัน '
                      'กรุณาขีดฆ่าและระบุตัวเลขที่ถูกต้องพร้อมเขียนชื่อตำรา หน้า และปีพิมพ์ในช่องหมายเหตุ '
                      'ห้ามอนุมัติรายการยาที่ไม่มีหลักฐานทางคลินิกรองรับอย่างชัดเจนเด็ดขาด',
                      style: pw.TextStyle(fontSize: 9, color: PdfColors.brown900, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // Group drugs into batches for multi-page detail listing
  final chunks = <List<Drug>>[];
  const chunkSize = 3; // 3 drugs per page for readability and notes space
  for (var i = 0; i < allDrugs.length; i += chunkSize) {
    chunks.add(allDrugs.sublist(i, i + chunkSize > allDrugs.length ? allDrugs.length : i + chunkSize));
  }

  for (var pageIdx = 0; pageIdx < chunks.length; pageIdx++) {
    final drugChunk = chunks[pageIdx];

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'DRUGPH CLINICAL VERIFICATION DOSSIER — แบบตรวจรับรองรายการยา',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800),
                  ),
                  pw.Text(
                    'หน้า ${pageIdx + 2} จาก ${chunks.length + 2}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.teal700, thickness: 1),
              pw.SizedBox(height: 6),

              // Drugs list
              ...drugChunk.map((drug) => _buildDrugVerificationBlock(drug)),
            ],
          );
        },
      ),
    );
  }

  // Final Sign-off Page: Signatures & Certification
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: theme,
      margin: const pw.EdgeInsets.all(36),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'หนังสือรับรองความถูกต้องทางคลินิก (Clinical Verification Certification)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'ข้าพเจ้าขอรับรองว่าได้ตรวจสอบขนาดยา สูตรการคำนวณ เกณฑ์การปรับยาตามระดับไต และคำเตือนความปลอดภัยทางยา '
              'ในระบบ Drugph เทียบเคียงกับตำรามาตรฐานสากลและแนวทางเวชปฏิบัติของประเทศไทยอย่างละเอียดเรียบร้อยแล้ว',
              style: const pw.TextStyle(fontSize: 10, lineSpacing: 1.4),
            ),
            pw.SizedBox(height: 24),

            // Pharmacist Box
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
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
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                      ),
                      pw.Text(
                        '[  ] ตรวจผ่านทุกรายการ  [  ] มีรายการแก้ไข',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 18),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text('ลงชื่อ: _________________________________________', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        child: pw.Text('( ภก./ภญ. ___________________________________ )', style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text('เลขที่ใบประกอบวิชาชีพเภสัชกรรม: ภ. _______________', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        child: pw.Text('วันที่: _____ / _____ / ________', style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('ตำแหน่ง / แผนก: ____________________________________________________________________', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Attending Physician / Chair Box
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
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
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                      ),
                      pw.Text(
                        '[  ] อนุมัติใช้งานทางคลินิก',
                        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 18),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text('ลงชื่อ: _________________________________________', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        child: pw.Text('( นพ./พญ./ศ./ผศ. _____________________________ )', style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  pw.Row(
                    children: [
                      pw.Expanded(
                        child: pw.Text('เลขที่ใบประกอบวิชาชีพเวชกรรม: ว. _______________', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Expanded(
                        child: pw.Text('วันที่: _____ / _____ / ________', style: const pw.TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text('ตำแหน่ง / สถาบัน: ____________________________________________________________________', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Footer note
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                'หมายเหตุ: เมื่อลงลายมือชื่อรับรองครบถ้วนแล้ว ให้สแกนเอกสารฉบับนี้จัดเก็บในระบบเพื่อเป็นบันทึกการตรวจสอบคุณภาพ (Audit Trail) '
                'และบันทึกชื่อผู้ตรวจ เลขที่ใบอนุญาต และวันที่ลงในฟิลด์ Provenance ของซอร์สโค้ดตามระเบียบ docs/VERIFICATION_PROTOCOL.md',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800, lineSpacing: 1.3),
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
  print('Pages: ${chunks.length + 2}');
  print('====================================================');
}

pw.Widget _buildBullet(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 3, left: 8),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
  );
}

pw.Widget _buildStatBox(String title, String value) {
  return pw.Container(
    width: 110,
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
    decoration: pw.BoxDecoration(
      color: PdfColor.fromHex('#F1F5F9'),
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: PdfColors.grey300),
    ),
    child: pw.Column(
      children: [
        pw.Text(title, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700), textAlign: pw.TextAlign.center),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900), textAlign: pw.TextAlign.center),
      ],
    ),
  );
}

pw.Widget _buildDrugVerificationBlock(Drug drug) {
  final hasMonograph = drug.monograph != null;
  final citation = drug.sourceCitation.isNotEmpty
      ? drug.sourceCitation
      : (drug.monograph?.textbookName ?? 'UNVERIFIED (รอยืนยัน)');
  final badges = <String>[];
  if (drug.isHighAlert) badges.add('HIGH-ALERT');
  if (drug.requiresTDM) badges.add('TDM');
  if (drug.requiresRenalAdjustment) badges.add('RENAL-ADJ');
  if (drug.requiresHepaticCaution) badges.add('HEPATIC');

  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.all(8),
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
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900),
                  ),
                  if (drug.nameTh != null && drug.nameTh!.isNotEmpty) ...[
                    pw.Text(' (${drug.nameTh})', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  ],
                ],
              ),
            ),
            if (badges.isNotEmpty)
              pw.Text(
                badges.join(' | '),
                style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
              ),
          ],
        ),
        pw.SizedBox(height: 3),

        // Citation row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Expanded(
              child: pw.Text(
                'แหล่งอ้างอิง: $citation',
                style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blueGrey800),
              ),
            ),
            pw.Text(
              hasMonograph ? 'Status: VERIFIED' : 'Status: PENDING REVIEW',
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: hasMonograph ? PdfColors.green800 : PdfColors.orange800,
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 4),

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
                _buildTableCell('เกณฑ์ปรับตามไต (CrCl)', isHeader: true, flex: 4),
              ],
            ),
            ...drug.regimens.map((r) {
              final renalStr = r.renalAdjustments != null && r.renalAdjustments!.isNotEmpty
                  ? r.renalAdjustments!
                      .map((ra) => 'CrCl ${ra.crclMin.toInt()}-${ra.crclMax.toInt()}: x${ra.adjustmentFactor} ${ra.adjustedFrequency?.displayEn ?? ''}')
                      .join('\n')
                  : (drug.requiresRenalAdjustment ? 'ปรับตามดุลยพินิจ' : 'ไม่ต้องปรับ');

              final formulaStr = r.fixedDose != null
                  ? '${r.fixedDose} ${r.doseUnit.symbol} ${r.frequency.displayEn}'
                  : (r.dosePerKg != null
                      ? '${r.dosePerKg} ${r.doseUnit.symbol}/kg ${r.frequency.displayEn}'
                      : (r.continuousRateMin != null
                          ? '${r.continuousRateMin}-${r.continuousRateMax} ${r.continuousRateUnit}'
                          : '${r.dosingType.nameEn}'));

              final limitStr = r.limits?.maxSingleDose != null
                  ? 'Max: ${r.limits!.maxSingleDose} ${r.doseUnit.symbol}'
                  : (r.limits?.maxDailyDose != null ? 'Daily: ${r.limits!.maxDailyDose} ${r.doseUnit.symbol}' : '-');

              return pw.TableRow(
                children: [
                  _buildTableCell('${r.indication ?? 'ขนาดยาทั่วไป'}\n[${r.route.nameEn}]', flex: 3),
                  _buildTableCell(formulaStr, flex: 3),
                  _buildTableCell(limitStr, flex: 2),
                  _buildTableCell(renalStr, flex: 4),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 4),

        // Pharmacist sign-off checklist row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '[  ] โดสถูกต้องตามตำรา     [  ] ตารางไตถูกต้อง     [  ] มีข้อทักท้วง (ระบุ): _______________________',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
            ),
            pw.Text(
              'ลงชื่อผู้ตรวจ: ___________',
              style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
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
        fontSize: 7,
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: isHeader ? PdfColors.teal900 : PdfColors.black,
      ),
    ),
  );
}
