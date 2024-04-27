import 'pnml.dart';

class Post {
  late String title;
  late Node main;
  String raw;
  DateTime created;

  Post(this.raw, this.created) {
    var tree = parsePNML(raw, '@');
    var titleNode = tree.find('@title')!;
    title = titleNode.children[0].data;
    var mainNode = tree.find('@main')!;
    main = mainNode;
    var createdNode = Node('@created');
    createdNode.children.add(Node(created.millisecondsSinceEpoch.toString()));
    tree.children.add(createdNode);
    raw = tree.children.map((e) => e.toString()).join('\n');
  }
}
