import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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

    final systemInstruction = Content.system('''
You are an expert Clinical Pharmacist AI Assistant.
Your role is to provide highly accurate, evidence-based pharmacological information.
Strict Rules:
1. ONLY answer questions related to medicine, pharmacy, pharmacology, and nursing. If asked about general knowledge or unrelated topics, politely decline.
2. ALWAYS state that your advice does not replace a doctor.
3. REFUSE to calculate exact dosages based on patient weight/renal function. Instead, refer the user to use the app's deterministic dosage calculator.
4. Be concise, professional, and use clinical terminology.
5. Answer in the language the user asked (English or Thai).
    ''');

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
      systemInstruction: systemInstruction,
      generationConfig: GenerationConfig(temperature: 0.2),
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
