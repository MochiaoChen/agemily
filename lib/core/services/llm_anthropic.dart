import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../models/llm_config.dart';
import '../models/message.dart';
import '../models/usage.dart';
import 'llm_client.dart';

class AnthropicClient implements LlmClient {
  Dio? _dio;

  Dio _getDio() {
    _dio ??= Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(minutes: 5),
    ));
    return _dio!;
  }

  @override
  Stream<LlmEvent> stream({
    required LlmConfig config,
    required List<Message> messages,
    required String? systemPrompt,
    int? maxTokens,
  }) async* {
    final dio = _getDio();
    final url = '${config.baseUrl}/v1/messages';

    final body = _buildRequestBody(
      config: config,
      messages: messages,
      systemPrompt: systemPrompt,
      maxTokens: maxTokens,
    );

    final Response<ResponseBody> response;
    try {
      response = await dio.post<ResponseBody>(
        url,
        data: jsonEncode(body),
        options: Options(
          headers: _buildHeaders(config),
          responseType: ResponseType.stream,
        ),
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final code = e.response!.statusCode;
        switch (code) {
          case 401:
            yield LlmError('API 密钥无效，请检查设置');
          case 403:
            yield LlmError('API 密钥权限不足');
          case 429:
            yield LlmError('请求过于频繁，请稍后再试');
          case 529:
            yield LlmError('服务暂时过载，请稍后再试');
          default:
            yield LlmError('服务请求失败 ($code)');
        }
      } else {
        yield LlmError('网络连接失败，请检查网络');
      }
      return;
    }

    yield* _parseSSEStream(response.data!.stream);
  }

  Map<String, String> _buildHeaders(LlmConfig config) {
    return {
      'content-type': 'application/json',
      'accept': 'text/event-stream',
      'x-api-key': config.apiKey,
      'anthropic-version': '2023-06-01',
    };
  }

  Map<String, dynamic> _buildRequestBody({
    required LlmConfig config,
    required List<Message> messages,
    required String? systemPrompt,
    int? maxTokens,
  }) {
    final body = <String, dynamic>{
      'model': config.model.id,
      'max_tokens': maxTokens ?? (config.model.maxTokens ~/ 2),
      'stream': true,
      'messages': _convertMessages(messages),
    };

    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      body['system'] = systemPrompt;
    }

    if (config.searchEnabled) {
      body['tools'] = [
        {
          'type': 'web_search_20250305',
          'name': 'web_search',
          'max_uses': 5,
        },
      ];
    }

    return body;
  }

  List<Map<String, dynamic>> _convertMessages(List<Message> messages) {
    final result = <Map<String, dynamic>>[];

    for (final msg in messages) {
      if (msg.role == MessageRole.system) continue;

      final role = msg.role == MessageRole.user ? 'user' : 'assistant';

      if (msg.role == MessageRole.user) {
        // Check if message contains media (images or audio)
        final hasMedia = msg.content.any((b) => b is ImageBlock || b is AudioBlock);
        if (hasMedia) {
          final contentArray = <Map<String, dynamic>>[];
          for (final block in msg.content) {
            if (block is ImageBlock) {
              contentArray.add({
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': block.mimeType,
                  'data': block.data,
                },
              });
            } else if (block is AudioBlock) {
              contentArray.add({
                'type': 'input_audio',
                'source': {
                  'type': 'base64',
                  'media_type': block.mimeType,
                  'data': block.data,
                },
              });
            } else if (block is TextBlock && block.text.isNotEmpty) {
              contentArray.add({
                'type': 'text',
                'text': block.text,
              });
            }
          }
          if (contentArray.isNotEmpty) {
            result.add({'role': role, 'content': contentArray});
          }
        } else {
          result.add({
            'role': role,
            'content': msg.textContent,
          });
        }
      } else {
        // Assistant messages: send as plain text string for maximum compatibility
        final text = msg.textContent;
        if (text.isNotEmpty) {
          result.add({
            'role': role,
            'content': text,
          });
        }
      }
    }

    // Anthropic requires alternating user/assistant. Ensure first message is user.
    if (result.isNotEmpty && result.first['role'] != 'user') {
      result.insert(0, {'role': 'user', 'content': '...'});
    }

    // Ensure no consecutive same-role messages
    final merged = <Map<String, dynamic>>[];
    for (final msg in result) {
      if (merged.isNotEmpty && merged.last['role'] == msg['role']) {
        // Merge into previous
        merged.last['content'] = '${merged.last['content']}\n${msg['content']}';
      } else {
        merged.add(Map<String, dynamic>.from(msg));
      }
    }

    return merged;
  }

  Stream<LlmEvent> _parseSSEStream(Stream<List<int>> byteStream) async* {
    final controller = StreamController<LlmEvent>();
    var usage = const TokenUsage();
    var buffer = '';

    final stringStream = utf8.decoder.bind(byteStream);
    final sub = stringStream.listen(
      (chunk) {
        buffer += chunk;
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // keep incomplete line

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final data = line.substring(6).trim();
            if (data.isEmpty || data == '[DONE]') continue;

            try {
              final event = jsonDecode(data) as Map<String, dynamic>;
              final type = event['type'] as String?;

              switch (type) {
                case 'message_start':
                  final msgUsage = event['message']?['usage'] as Map<String, dynamic>?;
                  if (msgUsage != null) {
                    usage = TokenUsage(
                      inputTokens: (msgUsage['input_tokens'] as num?)?.toInt() ?? 0,
                      outputTokens: (msgUsage['output_tokens'] as num?)?.toInt() ?? 0,
                      cacheReadTokens: (msgUsage['cache_read_input_tokens'] as num?)?.toInt() ?? 0,
                      cacheWriteTokens: (msgUsage['cache_creation_input_tokens'] as num?)?.toInt() ?? 0,
                    );
                    controller.add(LlmMessageStart(usage));
                  }
                  break;

                case 'content_block_start':
                  // Handle web_search_tool_result blocks — silently consume
                  // so they don't interfere with normal text streaming.
                  break;

                case 'content_block_delta':
                  final delta = event['delta'] as Map<String, dynamic>?;
                  if (delta != null) {
                    final deltaType = delta['type'] as String?;
                    if (deltaType == 'text_delta') {
                      final text = delta['text'] as String? ?? '';
                      if (text.isNotEmpty) {
                        controller.add(LlmTextDelta(text));
                      }
                    } else if (deltaType == 'thinking_delta') {
                      final thinking = delta['thinking'] as String? ?? '';
                      if (thinking.isNotEmpty) {
                        controller.add(LlmThinkingDelta(thinking));
                      }
                    }
                    // input_json_delta (web search query) — silently skip
                  }
                  break;

                case 'content_block_stop':
                  break;

                case 'message_delta':
                  final delta = event['delta'] as Map<String, dynamic>?;
                  final msgUsage = event['usage'] as Map<String, dynamic>?;
                  final stopReason = delta?['stop_reason'] as String?;
                  if (msgUsage != null) {
                    usage = usage.copyWith(
                      outputTokens: (msgUsage['output_tokens'] as num?)?.toInt() ?? usage.outputTokens,
                    );
                  }
                  controller.add(LlmMessageComplete(
                    stopReason: stopReason,
                    usage: usage,
                  ));
                  break;

                case 'message_stop':
                  break;

                case 'error':
                  final error = event['error'] as Map<String, dynamic>?;
                  controller.add(LlmError(
                    error?['message'] as String? ?? 'Unknown API error',
                  ));
                  break;

                case 'ping':
                  break;
              }
            } catch (_) {
              // Skip malformed JSON lines
            }
          }
        }
      },
      onError: (_) {
        controller.add(LlmError('连接中断，请重试'));
        controller.close();
      },
      onDone: () {
        controller.close();
      },
    );

    yield* controller.stream;
    await sub.cancel();
  }

  @override
  Future<void> testConnection(LlmConfig config) async {
    final dio = _getDio();
    final url = '${config.baseUrl}/v1/messages';

    try {
      final response = await dio.post(
        url,
        data: jsonEncode({
          'model': config.model.id,
          'max_tokens': 10,
          'messages': [
            {'role': 'user', 'content': 'Hi'}
          ],
        }),
        options: Options(
          headers: _buildHeaders(config),
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final code = e.response!.statusCode;
        switch (code) {
          case 401:
            throw Exception('API 密钥无效');
          case 403:
            throw Exception('API 密钥权限不足');
          default:
            throw Exception('服务请求失败 ($code)');
        }
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _dio?.close();
    _dio = null;
  }
}
