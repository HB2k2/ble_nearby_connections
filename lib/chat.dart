import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_application_19/global.dart';
import 'package:nearby_connections/nearby_connections.dart';

class ChatPage extends StatefulWidget {
  final Map<String, ConnectionInfo> endpointMap;
  // final String userInput;

  ChatPage({
    required this.endpointMap,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  // List<String> chatMessages = [];
  TextEditingController textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Page'),
        actions: [
          IconButton(
            onPressed: () async {
              await Nearby().disconnectFromEndpoint();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(chatMessages[index]),
                );
              },
            ),
          ),
          // Input field and send button
          Padding(
            padding: const EdgeInsets.only(bottom: 25.0),
            child: _buildInputField(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
              ),
              onSubmitted: (message) {
                _sendMessage(message);
              },
            ),
          ),
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              _sendMessage(textController.text);
              textController.clear();
            },
          ),
        ],
      ),
    );
  }

  void showSnackbar(dynamic a) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.toString()),
    ));
  }

  void _sendMessage(String message) {
    // Update the chatMessages list
    setState(() {
      chatMessages.add('You: $message');
    });

    // Send the message to all connected devices
    widget.endpointMap.forEach((key, value) {
      showSnackbar("Sending $message to ${value.endpointName}, id: $key");
      Nearby().sendBytesPayload(key, Uint8List.fromList(message.codeUnits));
    });
  }
}
