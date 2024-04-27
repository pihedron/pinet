import 'dart:collection';

class Node {
  String data;
  List<Node> children = [];
  Node(this.data);

  // index Node using Queue path
  Node operator [](Queue<int> queue) {
    if (queue.isEmpty) return this;
    var index = queue.removeFirst();
    return children[index][queue];
  }

  Node? find(String query) {
    if (query == data) return this;
    for (var child in children) {
      var node = child.find(query);
      if (node != null) return node;
    }
    return null;
  }

  @override
  String toString([int indent = 0]) {
    var str = '\t' * indent + data;
    if (children.isNotEmpty) str += '\n${children.map((e) => e.toString(indent + 1) + '\n').join()}';
    return str;
  }
}

// PiNet Markup Language
Node parsePNML(String pnml, String rootName) {
  var root = Node(rootName);
  var lines = pnml.split('\n');
  var current = root;
  List<int> stack = [];
  for (int i = 0; i < lines.length; i++) {
    var line = lines[i].trim(); // remove tabs and leading whitespace
    if (line.startsWith('@')) {
      stack.add(current.children.length);
      current.children.add(Node(line));
      current = current.children.last;
    } else if (line == '') {
      stack.removeLast();
      current = root[Queue.from(stack)];
    } else {
      current.children.add(Node(line));
    }
  }
  return root;
}