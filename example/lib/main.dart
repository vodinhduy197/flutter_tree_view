import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: CustomTreeView(),
      ),
    );
  }
}

class Item {
  static int _autoIncrement = 0;
  static String createUniqueId() => '${_autoIncrement++}';

  Item({
    required this.label,
    this.children = const [],
  }) : id = Item.createUniqueId();

  final String id;
  final String label;
  final List<Item> children;

  bool isExpanded = false;
}

class CustomTreeView extends StatefulWidget {
  const CustomTreeView({super.key});

  @override
  State<CustomTreeView> createState() => _CustomTreeViewState();
}

class _CustomTreeViewState extends State<CustomTreeView> {
  late final List<Item> rootItems;
  late final TreeDelegate<Item> _treeDelegate;

  @override
  void initState() {
    super.initState();

    rootItems = <Item>[
      Item(
        label: 'Root 1',
        children: [
          Item(
            label: 'Item 1.A',
            children: [
              Item(label: 'Item 1.A.1'),
              Item(label: 'Item 1.A.2'),
            ],
          ),
          Item(label: 'Item 1.B'),
        ],
      ),
      Item(
        label: 'Root 2',
        children: [
          Item(
            label: 'Item 2.A',
            children: List<Item>.generate(
              20,
              (int index) => Item(label: 'Item 2.A.${index + 1}'),
            ),
          ),
        ],
      ),
    ];

    _treeDelegate = TreeDelegate<Item>.fromHandlers(
      getRootItems: () => rootItems,
      getUniqueId: (Item item) => item.id,
      getChildren: (Item item) => item.children,
      getExpansion: (Item item) => item.isExpanded,
      setExpansion: (Item item, bool expanded) => item.isExpanded = expanded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TreeView<Item>(
      delegate: _treeDelegate,
      builder: (BuildContext context, TreeNode<Item> node) {
        return CustomTreeTile(node: node);
      },
    );
  }
}

class CustomTreeTile extends StatelessWidget {
  const CustomTreeTile({super.key, required this.node});

  final TreeNode<Item> node;

  @override
  Widget build(BuildContext context) {
    final String label = node.item.label;
    final int childCount = node.item.children.length;

    return TreeTile<Item>(
      node: node,
      guide: const IndentGuide.connectingLines(indent: 24, thickness: 1),
      onTap: () => SliverTree.of<Item>(context).toggle(node.item),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity,
          child: Text('$label - Children: $childCount'),
        ),
      ),
    );
  }
}
