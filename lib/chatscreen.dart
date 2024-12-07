import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.imageFile});

  final File imageFile;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: 'AIzaSyDzs3RHpBdo5q6JwtqxDlgg1BpSpAcMNRA',
    );
    _chat = _model.startChat();
    _sendImage(widget.imageFile);
  }

  Future<void> _sendImage(File imageFile) async {
    setState(() {
      _loading = true;
      _messages.add({'isUser': true, 'content': imageFile});
    });

    try {
      final imageBytes = await imageFile.readAsBytes();
      final content = Content.multi([
        DataPart('image/png', imageBytes),
        TextPart(
            'Please provide a detailed solution for the question in the image.'),
      ]);

      final response = await _chat.sendMessage(content);
      final text = response.text ?? 'No response from API.';

      setState(() {
        _messages.add({'isUser': false, 'content': text});
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'isUser': false, 'content': 'Error: $e'});
        _loading = false;
      });
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add({'isUser': true, 'content': message});
      _loading = true;
    });

    try {
      final response = await _chat.sendMessage(Content.text(message));
      final text = response.text ?? 'No response from API.';

      setState(() {
        _messages.add({'isUser': false, 'content': text});
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'isUser': false, 'content': 'Error: $e'});
        _loading = false;
      });
    }
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    if (message['content'] is File) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            message['content'],
            width: 280,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: message['isUser']
                ? [Colors.amber.shade400, Colors.amber.shade600]
                : [Colors.amber.shade100, Colors.amber.shade200],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: MarkdownBody(
          data: message['content'],
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: message['isUser'] ? Colors.white : Colors.black87,
              fontSize: 16,
              height: 1.4,
            ),
            code: TextStyle(
              backgroundColor: Colors.amber.shade50,
              color: Colors.black87,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: const Text(
          'Solution',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: "SF Pro",
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Align(
                    alignment: message['isUser']
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: _buildMessage(message),
                  ),
                );
              },
            ),
          ),
          if (_loading)
            Container(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                backgroundColor: Colors.amber.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.amber.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.shade100,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ask follow-up questions...',
                      hintStyle: TextStyle(color: Colors.brown.shade300),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    onPressed: () => _sendMessage(_textController.text),
                    color: Colors.brown,
                    splashRadius: 24,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
