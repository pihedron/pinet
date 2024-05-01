import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'post.dart';
import 'firebase.dart';

var fb = Firebase(firebaseConfig['projectId']!);

Response _root(Request request) {
  return Response.ok('@message\n\tPiNet');
}

Future<Response> _createPost(Request request) async {
  final group = request.params['group']!;
  final text = await request.readAsString();
  Post post = Post(text, DateTime.now());
  var doc = await fb.read(['groups', group]);
  int count = int.parse(doc.fields['posts']!['integerValue']!);
  await fb.create(['groups', group, 'posts', count.toString()], post.toMap());
  await fb.update(['groups', group], { 'posts': count + 1 }, 'posts');
  return Response.ok('@message\n\tsuccess');
}

Future<Response> _viewPosts(Request request) async {
  final group = request.params['group']!;
  var text = '@list';
  var docs = await fb.readAll(['groups', group, 'posts']);
  for (var i = 0; i < docs.length; i++) {
    text += '\n\t/groups/$group/posts/$i ${docs[i].fields['title']!['stringValue']}';
  }
  return Response.ok(text);
}

Future<Response> _viewPost(Request request) async {
  final group = request.params['group']!;
  final id = request.params['id']!;
  return Response.ok((await fb.read(['groups', group, 'posts', id])).fields['raw']!['stringValue']!.toString());
}

final _router = Router()
  ..get('/', _root)
  ..post('/groups/<group>/posts', _createPost)
  ..get('/groups/<group>/posts', _viewPosts)
  ..get('/groups/<group>/posts/<id|[0-9]+>', _viewPost);

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;

  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('PORT: ${server.port}');
}
