import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

/// LLMService handles interactions with the local LM Studio endpoint at http://localhost:1234
/// It supports streaming chat completions (reading chunked responses) and a fallback non-stream mode.
///
/// Note: This implementation assumes LM Studio's API is compatible with OpenAI-like /v1/chat/completions
/// with a `stream: true` option that returns chunked JSON lines or SSE-style chunks. Adjust payload to match your LLM.
class LLMService {
  final Uri baseUri;
  final http.Client httpClient;

  LLMService({String baseUrl = 'http://localhost:1234', http.Client? client})
      : baseUri = Uri.parse(baseUrl),
        httpClient = client ?? http.Client();

  /// Sends chat messages to the LLM and returns a stream of partial assistant text as they arrive.
  ///
  /// messages: List of ChatMessage (last N messages included).
  /// streamTokens: yields successive text fragments (may be a token or several tokens).
  Stream<String> streamChatCompletion({
    required List<ChatMessage> messages,
    String model = 'nous-hermes-1', // default; adjust as needed
  }) async* {
    final endpoint = baseUri.replace(path: '/v1/chat/completions');
    final payload = {
      "model": model,
      // Convert our ChatMessage to the API's expected structure
      "messages": messages
          .map((m) => {
                "role": m.role == MessageRole.user ? "user" : (m.role == MessageRole.assistant ? "assistant" : "system"),
                "content": m.content
              })
          .toList(),
      "stream": true, // request streaming
    };

    final request = http.Request('POST', endpoint);
    request.headers.addAll({'Content-Type': 'application/json'});
    request.body = jsonEncode(payload);

    final streamedResponse = await httpClient.send(request);

    if (streamedResponse.statusCode >= 400) {
      final body = await streamedResponse.stream.bytesToString();
      throw Exception('LLM responded with ${streamedResponse.statusCode}: $body');
    }

    // Read the byte stream and parse chunks. LM Studio may return SSE-like "data: {...}\n\n"
    final stream = streamedResponse.stream.transform(utf8.decoder);

    // A simple parser for SSE-like or newline-delimited JSON chunks:
    // Accumulate lines and whenever we encounter a JSON chunk, parse it and emit text.
    final buffer = StringBuffer();
    await for (final chunk in stream) {
      buffer.write(chunk);
      // Split on SSE delimiter "\n\n" or newline-delimited JSON
      final content = buffer.toString();
      // handle multiple chunks
      final parts = content.split(RegExp(r'\n\n'));
      // Keep last part if it doesn't end with delimiter
      for (var i = 0; i < parts.length - 1; i++) {
        final part = parts[i].trim();
        if (part.isEmpty) continue;
        // Remove leading "data: " if present
        final cleaned = part.split('\n').map((l) => l.startsWith('data:') ? l.substring(5).trim() : l).join();
        try {
          final jsonObj = jsonDecode(cleaned);
          // Attempt to extract token/text from common fields
          final delta = _extractTextFromChunk(jsonObj);
          if (delta != null && delta.isNotEmpty) yield delta;
        } catch (e) {
          // If not JSON, just yield as raw
          yield cleaned;
        }
      }
      // Set buffer to last unfinished part
      buffer.clear();
      buffer.write(parts.last);
    }
  }

  /// Non-streaming fallback: gets full assistant reply.
  Future<String> chatCompletion({
    required List<ChatMessage> messages,
    String model = 'nous-hermes-1',
  }) async {
    final endpoint = baseUri.replace(path: '/v1/chat/completions');
    final payload = {
      "model": model,
      "messages": messages
          .map((m) => {
                "role": m.role == MessageRole.user ? "user" : (m.role == MessageRole.assistant ? "assistant" : "system"),
                "content": m.content
              })
          .toList(),
      "stream": false,
      "max_tokens": 1024
    };
    final res = await httpClient.post(endpoint, headers: {'Content-Type': 'application/json'}, body: jsonEncode(payload));
    if (res.statusCode >= 400) throw Exception('LLM error ${res.statusCode}: ${res.body}');
    final data = jsonDecode(res.body);
    // parse typical openai-style structure
    if (data['choices'] != null && data['choices'].isNotEmpty) {
      return data['choices'][0]['message']['content'] ?? '';
    }
    return '';
  }

  /// Helper: tries to parse common streaming chunk formats (OpenAI delta, LM Studio, etc.)
  String? _extractTextFromChunk(dynamic jsonObj) {
    try {
      if (jsonObj is Map && jsonObj.containsKey('choices')) {
        final choice = jsonObj['choices'][0];
        // openai-like: delta: { content: "..." }
        if (choice.containsKey('delta') && choice['delta'] is Map && choice['delta'].containsKey('content')) {
          return choice['delta']['content'] as String;
        }
        // or 'text' field
        if (choice.containsKey('text')) return choice['text'] as String;
        // or full message
        if (choice.containsKey('message') && choice['message'] is Map && choice['message'].containsKey('content')) {
          return choice['message']['content'] as String;
        }
      }
      // LM Studio might stream direct {"data": {"text": "..."}}
      if (jsonObj is Map && jsonObj.containsKey('data')) {
        final data = jsonObj['data'];
        if (data is Map && data.containsKey('text')) return data['text'] as String;
      }
    } catch (_) {}
    return null;
  }
}
