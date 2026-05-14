import 'package:chatmcp/mcp/models/json_rpc_message.dart';
import 'package:flutter/material.dart';

// define JSON-RPC response class
class JsonRpcResponse {
  final String jsonrpc;
  final dynamic result;
  final Map<String, dynamic>? error;
  final dynamic id;

  JsonRpcResponse({required this.jsonrpc, this.result, this.error, required this.id});

  factory JsonRpcResponse.fromJson(Map<String, dynamic> json) {
    return JsonRpcResponse(
      jsonrpc: json['jsonrpc'] ?? '2.0',
      id: json['id'],
      result: json['result'],
      error: json['error'] != null ? Map<String, dynamic>.from(json['error']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'jsonrpc': jsonrpc, 'id': id};
    // according to JSON-RPC specification, result and error are mutually exclusive
    if (error != null) {
      data['error'] = error;
    } else {
      // even if result is null or empty map, it should be included (if error does not exist)
      data['result'] = result;
    }
    return data;
  }
}

// function to handle request
JsonRpcResponse handleRequest(JSONRPCMessage request) {
  dynamic result;
  Map<String, dynamic>? error;

  try {
    switch (request.method) {
      case 'initialize':
        result = {
          'protocolVersion': '1.0',
          'serverInfo': {'name': 'mock-server-dart', 'version': '1.0.0'},
          'capabilities': {
            'prompts': {'listChanged': true},
            'resources': {'listChanged': true, 'subscribe': true},
            'tools': {'listChanged': true},
          },
        };
        break;
      case 'ping':
        result = {}; // empty object
        break;
      case 'resources/list':
        result = {
          'resources': [
            {'name': 'test-resource', 'uri': 'test://resource'},
          ],
        };
        break;
      case 'resources/read':
        // in actual implementation, should get URI from request.params
        // final uri = request.params?['uri'];
        // if (uri == null) throw ArgumentError('Missing parameter: uri');
        // ... read content according to uri ...
        result = {
          'contents': [
            {
              'text': 'test content',
              'uri': 'test://resource', // use mock URI
            },
          ],
        };
        break;
      case 'resources/subscribe':
      case 'resources/unsubscribe':
        // in actual implementation, should handle subscribe/unsubscribe logic
        // final uri = request.params?['uri'];
        // if (uri == null) throw ArgumentError('Missing parameter: uri');
        result = {}; // return empty object when successful
        break;
      case 'prompts/list':
        result = {
          'prompts': [
            {'name': 'test-prompt'},
          ],
        };
        break;
      case 'prompts/get':
        // in actual implementation, should get prompt name/ID from request.params
        // final promptName = request.params?['name'];
        result = {
          'messages': [
            {
              'role': 'assistant',
              'content': {'type': 'text', 'text': 'test message'},
            },
          ],
        };
        break;
      case 'tools/list':
        result = {
          'tools': [
            {
              'name': 'test-tool',
              'inputSchema': {
                'type': 'object',
                // 'properties': { ... } // can add schema definition
              },
              // 'description': 'A test tool' // optional description
            },
          ],
        };
        break;
      case 'tools/call':
        // in actual implementation, should get tool name and input from request.params
        // final toolName = request.params?['tool'];
        // final input = request.params?['input'];
        // if (toolName == null) throw ArgumentError('Missing parameter: tool');
        // ... execute tool call ...
        result = {
          'content': [
            {'type': 'text', 'text': 'tool result'},
          ],
        };
        break;
      case 'logging/setLevel':
        // in actual implementation, should get log level from request.params
        // final level = request.params?['level'];
        // if (level == null) throw ArgumentError('Missing parameter: level');
        result = {}; // return empty object when successful
        break;
      case 'completion/complete':
        // in actual implementation, should get completion info from request.params
        // final context = request.params?['context'];
        result = {
          'completion': {
            'values': ['test completion'],
          },
        };
        break;
      default:
        error = {
          'code': -32601, // Method not found
          'message': 'Method not found: ${request.method}',
        };
    }
  } catch (e, stackTrace) {
    // catch any exception in the process and format it as JSON-RPC error
    debugPrint('Error handling request: $e');
    debugPrint('Stack trace:\n$stackTrace');
    error = {
      'code': -32603, // Internal error
      'message': 'Internal server error: ${e.toString()}',
      // 'data': stackTrace.toString(), // optional: include debug info
    };
    result = null; // ensure result is null when error occurs
  }

  return JsonRpcResponse(jsonrpc: '2.0', id: request.id, result: result, error: error);
}
