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
  Item({
    required this.label,
    this.children = const [],
  }) : key = UniqueKey();

  final Key key;
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
  // Static tree
  late final roots = <Item>[
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
          children: [
            Item(label: 'Item 2.A.1'),
          ],
        ),
      ],
    ),
  ];

  late final TreeDelegate<Item> _treeDelegate;

  @override
  void initState() {
    super.initState();

    _treeDelegate = TreeDelegate<Item>.fromHandlers(
      findRootItems: () => roots,
      findChildren: (Item item) => item.children,
      getExpansionState: (Item item) => item.isExpanded,
      setExpansionState: (Item item, bool expanded) {
        item.isExpanded = expanded;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return TreeView<Item>(
      delegate: _treeDelegate,
      keyFactory: (Item item) => item.key,
      builder: (BuildContext context, TreeNode<Item> node) {
        final String label = node.item.label;
        final int childCount = node.item.children.length;

        return TreeTile<Item>(
          node: node,
          guide: const IndentGuide.connectingLines(indent: 24, thickness: 1),
          onTap: () => SliverTree.of(context).toggleItemExpansion(node.item),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('$label - Children: $childCount'),
          ),
        );
      },
    );
  }
}
