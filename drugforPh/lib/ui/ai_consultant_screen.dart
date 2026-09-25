import 'package:flutter/material.dart';
import 'package:google_generative_ai/flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiConsultantScreen extends StatefulWidget {
  final bool isThai;
  const AiConsultantScreen({super.key, required this.isThai});

  @override
  State<AiConsultantScreen> createState() => _AiConsultantScreenState();
}

class _AiConsultantScreenState extends State<AiConsultantScreen> {
  final TextEditingController _apiKeyCtrl = TextEditingController();
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  GenerativeModel? _model;
  ChatSession? _chat;
  
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  void _initModel() {
    if (_apiKeyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isThai ? 'กรุณาใส่ API Key' : 'Please enter API Key')),
      );
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
      apiKey: _apiKeyCtrl.text.trim(),
      systemInstruction: systemInstruction,
      generationConfig: GenerationConfig(temperature: 0.2), // Low temp for clinical accuracy
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
    
    FocusScope.of(context).unfocus();
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
        _messages.add({'isBot': true, 'text': 'Error: \${e.toString()}'});
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
      body: _chat == null ? _buildSetupScreen() : _buildChatScreen(),
    );
  }

  Widget _buildSetupScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.smart_toy, size: 80, color: Colors.indigo),
          const SizedBox(height: 16),
          Text(
            widget.isThai 
              ? 'ระบบ AI ใช้ Gemini API โปรดนำ API Key ฟรีมาใส่เพื่อเริ่มต้นใช้งาน'
              : 'AI System uses Gemini API. Please enter a free API Key to start.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _apiKeyCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Gemini API Key',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            onPressed: _initModel,
            child: Text(widget.isThai ? 'เริ่มใช้งาน AI' : 'Start AI Session'),
          ),
        ],
      ),
    );
  }

  Widget _buildChatScreen() {
    return Column(
      children: [
        Container(
          color: Colors.yellow.shade100,
          padding: const EdgeInsets.all(8),
          width: double.infinity,
          child: Text(
            widget.isThai
                ? '⚠️ คำเตือน: ข้อมูลจาก AI ใช้สำหรับการอ้างอิงเบื้องต้นเท่านั้น ห้ามใช้ AI คำนวณขนาดยาเด็ดขาด'
                : '⚠️ WARNING: AI information is for reference only. Do NOT use AI for dosage calculation.',
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isBot = msg['isBot'];
              return Align(
                alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isBot ? Colors.grey.shade200 : Colors.indigo.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  child: Text(
                    msg['text'],
                    style: const TextStyle(fontSize: 15),
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _msgCtrl,
                  decoration: InputDecoration(
                    hintText: widget.isThai ? 'ถามเรื่องยา...' : 'Ask about drugs...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.indigo,
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
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
