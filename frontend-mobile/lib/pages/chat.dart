import 'package:flutter/material.dart';
import '../services/api.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final List<Map<String, String>> messages = [];

  Future<void> send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => messages.add({'who': 'you', 'text': text}));
    _controller.clear();
    try {
      final res = await ApiClient().chatWithAI(text);
      setState(() => messages.add({'who': 'ai', 'text': res['response'] ?? 'No response'}));
    } catch (e) {
      setState(() => messages.add({'who': 'ai', 'text': 'Error: $e'}));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final m = messages[i];
                return ListTile(
                  title: Text(m['text'] ?? ''),
                  subtitle: Text(m['who'] ?? ''),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Ask the AI...'))),
                IconButton(onPressed: send, icon: const Icon(Icons.send)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
