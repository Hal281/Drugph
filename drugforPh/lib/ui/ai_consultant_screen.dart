import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../data/drug_database.dart';

class AiConsultantScreen extends StatefulWidget {
  final bool isThai;
  final String? initialDrugName;

  const AiConsultantScreen({
    super.key,
    required this.isThai,
    this.initialDrugName,
  });

  @override
  State<AiConsultantScreen> createState() => _AiConsultantScreenState();
}

class _AiConsultantScreenState extends State<AiConsultantScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  GenerativeModel? _model;
  ChatSession? _chat;

  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  // Production default proxy deployed on Cloudflare Workers
  static const String _defaultProxyUrl =
      'https://drugph-ai-proxy.turbodrugph.workers.dev';

  // Configured via --dart-define=AI_PROXY_URL=https://... with default fallback
  static const String _proxyUrl = String.fromEnvironment(
    'AI_PROXY_URL',
    defaultValue: _defaultProxyUrl,
  );
  // Fallback for local testing only via --dart-define=GEMINI_API_KEY=...
  static const String _directApiKey = String.fromEnvironment('GEMINI_API_KEY');

  // Regex to detect dose-like patterns in AI output
  static final RegExp _dosePattern = RegExp(
    r'\b\d+(\.\d+)?\s*(mg|mg/kg|mL/hr|ml/hr|units/kg|unit/kg|mcg|g\b)',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() {
    final hasProxy = _proxyUrl.isNotEmpty;
    final hasDirectKey = _directApiKey.isNotEmpty;

    if (!hasProxy && !hasDirectKey) {
      setState(() {
        _messages.add({
          'isBot': true,
          'text': widget.isThai
              ? '⚠️ **ยังไม่ได้กำหนดค่าระบบ AI:** กรุณากำหนด `AI_PROXY_URL` ผ่าน `--dart-define` หรือติดต่อผู้ดูแลระบบ'
              : '⚠️ **AI Service Not Configured:** Please configure `AI_PROXY_URL` via `--dart-define` or contact support.',
        });
      });
      return;
    }

    if (!hasProxy && hasDirectKey) {
      _initDirectModel();
    }

    final welcomeText = widget.initialDrugName != null
        ? (widget.isThai
            ? 'สวัสดีครับ ผมคือ AI ผู้ช่วยเภสัชกร มีข้อสงสัยด้านเภสัชวิทยา ข้อบ่งใช้ หรืออาการไม่พึงประสงค์ของยา **${widget.initialDrugName}** สอบถามได้เลยครับ\n\n*(หมายเหตุ: ระบบไม่รับคำนวณขนาดยา กรุณาใช้เครื่องคิดเลขหลักของแอป)*'
            : 'Hello! I am your Clinical Pharmacist AI Assistant. How can I help you with **${widget.initialDrugName}** today?\n\n*(Note: Exact dosage calculations must be done via the app calculator).*')
        : (widget.isThai
            ? 'สวัสดีครับ ผมคือ AI ผู้ช่วยเภสัชกร ยินดีให้คำปรึกษาเรื่องกลไกยา ข้อควรระวัง และอันตรกิริยาระหว่างยาครับ\n\n*(หมายเหตุ: ระบบไม่รับคำนวณขนาดยา กรุณาใช้เครื่องคิดเลขหลักของแอป)*'
            : 'Hello! I am your Clinical Pharmacist AI Assistant. How can I help you with evidence-based drug information today?\n\n*(Note: For dosing, please use the app calculator).*');

    setState(() {
      _messages.add({
        'isBot': true,
        'text': welcomeText,
      });
    });
  }

  void _initDirectModel() {
    final supportedDrugs = DrugDatabase.allDrugs.map((d) => d.genericName).join(', ');

    final systemInstruction = Content.system('''
You are an expert Senior Clinical Pharmacist AI.
Your primary goal is to provide accurate, evidence-based pharmacology information.

CRITICAL SAFETY RULES:
1. NO EXACT DOSAGE CALCULATIONS: You MUST REFUSE to calculate exact mg/kg dosages or renal adjustments. Reply: "Please use the deterministic Dosage Calculator in this application for precise and safe calculations."
2. NO DIAGNOSIS.
3. EVIDENCE-BASED ONLY: Cite reputable sources (Lexicomp, Sanford Guide, etc.).
4. PRIVACY: Never ask for or store patient names or hospital numbers.
Supported formulary in this app: $supportedDrugs.
''');

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _directApiKey,
      systemInstruction: systemInstruction,
      generationConfig: GenerationConfig(temperature: 0.1, topP: 0.8),
    );

    _chat = _model!.startChat();
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    _msgCtrl.clear();

    setState(() {
      _messages.add({'isBot': false, 'text': text});
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      String replyText;

      if (_proxyUrl.isNotEmpty) {
        replyText = await _callProxy(text);
      } else if (_chat != null) {
        final response = await _chat!.sendMessage(Content.text(text));
        replyText = response.text ?? (widget.isThai ? 'ไม่มีคำตอบ' : 'No response');
      } else {
        replyText = widget.isThai
            ? 'ไม่สามารถเชื่อมต่อระบบ AI ได้'
            : 'AI service unavailable';
      }

      // Output guard: detect dose-like numbers and prepend safety banner
      if (_dosePattern.hasMatch(replyText)) {
        final warning = widget.isThai
            ? '> ⚠️ **คำเตือนความปลอดภัย:** ข้อความด้านล่างมีตัวเลขขนาดยา ห้ามนำไปใช้กับผู้ป่วยจริงโดยตรง กรุณาใช้เครื่องมือ **เครื่องคิดเลขขนาดยา (Dosage Calculator)** ในแอปเพื่อความปลอดภัย\n\n'
            : '> ⚠️ **SAFETY WARNING:** This response mentions dosage amounts. Do NOT use these numbers directly on patients. Please use the deterministic **Dosage Calculator** in the app.\n\n';
        replyText = warning + replyText;
      }

      setState(() {
        _messages.add({'isBot': true, 'text': replyText});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('AiConsultant error: $e');
      setState(() {
        _messages.add({
          'isBot': true,
          'text': widget.isThai
              ? 'ขออภัย เกิดข้อผิดพลาดในการเชื่อมต่อกับระบบ AI กรุณาลองใหม่อีกครั้งในภายหลัง'
              : 'Sorry, a connection error occurred while contacting the AI service. Please try again later.'
        });
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<String> _callProxy(String message) async {
    final history = _messages
        .where((m) => m['text'] != null)
        .take(6)
        .map((m) => {
              'role': m['isBot'] == true ? 'model' : 'user',
              'text': m['text'],
            })
        .toList();

    final response = await http.post(
      Uri.parse(_proxyUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'history': history,
      }),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] as String? ?? 'No response generated.';
    } else {
      throw Exception('Proxy status: ${response.statusCode}');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isThai ? 'AI ผู้ช่วยเภสัชกร' : 'AI Pharmacist Consultant'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Persistent safety banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.isThai
                        ? 'ข้อมูลสร้างโดย AI อาจคลาดเคลื่อนได้ ไม่ใช้คำนวณขนาดยาจริง และต้องตรวจเทียบกับตำราอ้างอิงเสมอ'
                        : 'AI-generated info may be inaccurate. Not for real patient dosing; verify with primary sources.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildChatScreen()),
        ],
      ),
    );
  }

  Widget _buildChatScreen() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isBot = msg['isBot'] as bool;
              return Align(
                alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: isBot ? Colors.white : Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isBot ? const Radius.circular(0) : const Radius.circular(16),
                      bottomRight: isBot ? const Radius.circular(16) : const Radius.circular(0),
                    ),
                    border: Border.all(
                      color: isBot ? Colors.grey.shade300 : Colors.indigo.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isBot
                      ? MarkdownBody(
                          data: msg['text'] as String,
                          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                            p: const TextStyle(fontSize: 14, height: 1.4),
                          ),
                        )
                      : Text(
                          msg['text'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.indigo.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              );
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: widget.isThai ? 'ถามคำถามเรื่องยา (เช่น กลไก, ผลข้างเคียง)...' : 'Ask pharmacological questions...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.indigo,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
