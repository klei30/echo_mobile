import 'dart:convert';

class JSONRPCMessage {
  final String? id;
  final String jsonrpc;
  final String? method; // Method is not required for all messages
  final Map<String, dynamic>? params;
  final dynamic result;
  final dynamic error;

  JSONRPCMessage({this.id, this.jsonrpc = '2.0', this.method, this.params, this.result, this.error});

  factory JSONRPCMessage.fromJson(Map<String, dynamic> json) {
    return JSONRPCMessage(
      id: json['id']?.toString(),
      jsonrpc: json['jsonrpc']?.toString() ?? '2.0',
      method: json['method']?.toString(),
      params: json['params'] as Map<String, dynamic>?,
      result: json['result'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'jsonrpc': jsonrpc};

    if (method != null) json['method'] = method;
    if (id != null) json['id'] = id;
    if (params != null) json['params'] = params;
    if (result != null) json['result'] = result;
    if (error != null) json['error'] = error;

    return json;
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
