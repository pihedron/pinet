import 'dart:convert';
import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart';

const sucess = 200;

var prod = Platform.environment['PRODUCTION'];
var dotenv = DotEnv()..load();
Map<String, String> env = prod == 'true' ? Platform.environment : dotenv.map;

var firebaseConfig = {
  'apiKey': env['API_KEY'],
  'authDomain': '${env['PROJECT_ID']}.firebaseapp.com',
  'projectId': env['PROJECT_ID'],
  'storageBucket': '${env['PROJECT_ID']}.appspot.com',
  'messagingSenderId': env['MESSAGING_SENDER_ID'],
  'appId': env['APP_ID'],
  'measurementId': env['MEASUREMENT_ID']
};

class Document {
  String name;
  Map<String, Map<String, dynamic>> fields;
  DateTime createTime;
  DateTime updateTime;
  Document(this.name, this.fields, this.createTime, this.updateTime);
}

class Firebase {
  String projectId;
  Firebase(this.projectId);

  Future<Document> read(List<String> path) async {
    var response = await get(Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/${path.join('/')}'));
    Map<String, dynamic> data = json.decode(response.body);
    if (response.statusCode != sucess) throw Exception(data);
    return Document(data['name'], (data['fields'] as Map<String, dynamic>).cast(), DateTime.parse(data['createTime']), DateTime.parse(data['updateTime']));
  }

  Future<List<Document>> readAll(List<String> path) async {
    List<Document> docs = [];
    var response = await get(Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/${path.join('/')}'));
    Map<String, List<dynamic>> collection = (json.decode(response.body) as Map<String, dynamic>).cast();
    if (response.statusCode != sucess) throw Exception(collection);
    for (Map<String, dynamic> data in collection['documents']!) {
      docs.add(Document(data['name'], (data['fields'] as Map<String, dynamic>).cast(), DateTime.parse(data['createTime']), DateTime.parse(data['updateTime'])));
    }
    return docs;
  }

  Future<Document> create(List<String> path, Map<String, dynamic> fields) async {
    var body = encode(fields);
    var response = await post(Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/${path.sublist(0, path.length - 1).join('/')}?documentId=${path.last}'), headers: { 'Content-Type': 'application/json' }, body: json.encode(body));
    Map<String, dynamic> data = json.decode(response.body);
    if (response.statusCode != sucess) throw Exception(data);
    return Document(data['name'], (data['fields'] as Map<String, dynamic>).cast(), DateTime.parse(data['createTime']), DateTime.parse(data['updateTime']));
  }

  Future<Document> update(List<String> path, Map<String, dynamic> fields, [String? updateMask]) async {
    var body = encode(fields);
    var param = updateMask == null ? '' : '?updateMask.fieldPaths=$updateMask';
    var response = await patch(Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/${path.join('/')}$param'), headers: { 'Content-Type': 'application/json' }, body: json.encode(body));
    Map<String, dynamic> data = json.decode(response.body);
    if (response.statusCode != sucess) throw Exception(data);
    return Document(data['name'], (data['fields'] as Map<String, dynamic>).cast(), DateTime.parse(data['createTime']), DateTime.parse(data['updateTime']));
  }

  Map<String, dynamic> encode(Map<String, dynamic> fields) {
    Map<String, dynamic> body = {};
    body['fields'] = {};
    for (var key in fields.keys) {
      var value = fields[key];
      String typeName = '';
      if (value is int) {
        typeName = 'integer';
      } else if (value is bool) {
        typeName = 'bool';
      } else if (value is String) {
        typeName = 'string';
      }
      typeName += 'Value';
      body['fields'][key] = {};
      body['fields'][key][typeName] = value;
    }
    return body;
  }
}