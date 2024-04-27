import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import 'post.dart';

Map<String, List<Post>> topicPosts = {};

Response _root(Request request) {
  return Response.ok('PiNet');
}

Future<Response> _createPost(Request request) async {
  final topic = request.params['topic']!;
  final text = await request.readAsString();
  Post post = Post(text, DateTime.now());
  topicPosts[topic] ??= [];
  topicPosts[topic]!.add(post);
  return Response.ok('@message\n\tsuccess');
}

Future<Response> _viewPosts(Request request) async {
  final topic = request.params['topic']!;
  var text = '';
  for (var i = 0; i < topicPosts[topic]!.length; i++) {
    text += '\n\t/posts/$topic/$i ${topicPosts[topic]![i].title}';
  }
  return Response.ok('@list$text');
}

Future<Response> _viewPost(Request request) async {
  final topic = request.params['topic']!;
  final id = int.parse(request.params['id']!);
  return Response.ok(topicPosts[topic]![id].raw);
}

final _router = Router()
  ..get('/', _root)
  ..post('/posts/<topic>', _createPost)
  ..get('/posts/<topic>', _viewPosts)
  ..get('/posts/<topic>/<id|[0-9]+>', _viewPost);

void main(List<String> args) async {
  final ip = InternetAddress.anyIPv4;

  final handler =
      Pipeline().addMiddleware(logRequests()).addHandler(_router.call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('PORT: ${server.port}');
}
