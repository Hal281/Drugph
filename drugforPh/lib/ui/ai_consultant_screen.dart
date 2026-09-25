import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/models/drug.dart';
import '../data/drug_database.dart';

class AiConsultantScreen extends StatefulWidget {
  final bool isThai;
  const AiConsultantScreen({super.key, required this.isThai});

  @override
  State<AiConsultantScreen> createState() => _AiConsultantScreenState();
}

class _AiConsultantScreenState extends State<AiConsultantScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  GenerativeModel? _model;
  ChatSession? _chat;
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  void _initModel() {
    if (_apiKey.isEmpty) {
      setState(() {
        _messages.add({
          'isBot': true,
          'text': widget.isThai 
            ? 'ข้อผิดพลาด: ไม่พบ API Key กรุณาตั้งค่า GEMINI_API_KEY ใน GitHub Secrets และ Build ใหม่' 
            : 'Error: API Key not found. Please configure GEMINI_API_KEY in GitHub Secrets and rebuild.'
        });
      });
      return;
    }

    final supportedDrugs = DrugDatabase.allDrugs.map((d) => d.genericName).join(', ');

    final systemInstruction = Content.system('''
You are an expert Senior Clinical Pharmacist AI with 20 years of experience in pharmacotherapy, pharmacokinetics (PK), and pharmacodynamics (PD). 
Your primary goal is to provide highly accurate, evidence-based, and safe pharmacological information to healthcare professionals (doctors, pharmacists, nurses).

CRITICAL THINKING & DOUBLE VERIFICATION (ALWAYS ON):
Before generating any response, you MUST engage your critical thinking. Internally verify the drug class, mechanism of action, contraindications, and potential interactions. Double-check your own logic to minimize errors before outputting the final answer.

CRITICAL SAFETY RULES (ZERO TOLERANCE FOR HALLUCINATION):
1. NO DIAGNOSIS: You cannot diagnose conditions.
2. NO EXACT DOSAGE CALCULATIONS: You MUST REFUSE to calculate exact mg/kg dosages, renal adjustments, or infusion rates. If asked for a calculation, you MUST reply: "Please use the deterministic Dosage Calculator in this application for precise and safe calculations."
3. EVIDENCE-BASED ONLY: If you are not 100% certain of an interaction, adverse effect, or mechanism, state clearly: "I do not have sufficient clinical evidence to answer this safely." Do not guess.
4. SCOPE: ONLY answer questions related to medicine, pharmacy, pharmacology, clinical guidelines, and nursing. Politely decline unrelated topics.

MANDATORY CITATIONS & REFERENCES:
For EVERY medical or pharmacological claim you make, you MUST cite your source.
- You must draw knowledge ONLY from globally accepted, highly reputable clinical references (e.g., Lexicomp, Micromedex, UpToDate, Sanford Guide, Pharmacotherapy (DiPiro), Thai National Formulary, FDA/EMA guidelines, or peer-reviewed journals).
- State clearly where the information comes from at the end of your response under a "References" section.

APP CONTEXT:
The user is using a Clinical Pharmacokinetics App. 
The app currently has built-in calculators for the following drugs: $supportedDrugs.
If the user asks about a drug in this list, strongly encourage them to use the app's built-in tools for dosing and TDM.

COMMUNICATION STYLE & MANDATORY DISCLAIMER:
- Use precise clinical terminology.
- Structure answers clearly with bullet points.
- Answer in the language the user used (English or Thai).
- EVERY response MUST end with this exact disclaimer (translated to Thai if answering in Thai): 
"Disclaimer: This information is provided to support clinical decision-making only. It does not replace professional clinical judgment. Do not use this information for any purpose that violates medical ethics or the law."
    ''');

    _model = GenerativeModel(
      model: 'gemini-2.5-pro',
      apiKey: _apiKey,
      systemInstruction: systemInstruction,
      generationConfig: GenerationConfig(temperature: 0.1, topP: 0.8),
    );
    
    _chat = _model!.startChat();
    
    setState(() {
      _messages.add({
        'isBot': true,
        'text': widget.isThai 
          ? 'สวัสดีครับ ผมคือผู้ช่วยเภสัชกร AI ยินดีให้คำปรึกษาเรื่องยา (ไม่รับคำนวณขนาดยานะครับ กรุณาใช้เครื่องคิดเลขหลักของแอป)' 
          : 'Hello! I am your Clinical Pharmacist AI Assistant. How can I help you with drug information today?'
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty || _chat == null) return;
    
    final text = _msgCtrl.text.trim();
    _msgCtrl.clear();
    
    setState(() {
      _messages.add({'isBot': false, 'text': text});
      _isLoading = true;
    });
    
    _scrollToBottom();
    
    try {
      final response = await _chat!.sendMessage(Content.text(text));
      setState(() {
        _messages.add({'isBot': true, 'text': response.text ?? 'Error...'});
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({'isBot': true, 'text': 'Error: ${e.toString()}'});
        _isLoading = false;
      });
      _scrollToBottom();
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
        title: Text(widget.isThai ? 'AI ผู้ช่วยเภสัชกร' : 'AI Pharmacist'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _buildChatScreen(),
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
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: isBot ? Colors.white : Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomLeft: isBot ? const Radius.circular(0) : const Radius.circular(16),
                      bottomRight: isBot ? const Radius.circular(16) : const Radius.circular(0),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ]
                  ),
                  child: Text(
                    msg['text'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      color: isBot ? Colors.black87 : Colors.indigo.shade900,
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
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
            ]
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: widget.isThai ? 'ถามคำถามเรื่องยา...' : 'Ask about medications...',
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
              )
            ],
          ),
        ),
      ],
    );
  }
}
