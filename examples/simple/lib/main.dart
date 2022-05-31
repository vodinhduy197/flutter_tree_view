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
  });

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

  late final _dataSource = TreeDataSource<Item>.simple(
    findChildren: (Item? item) {
      return item?.children ?? roots;
    },
    findExpansionState: (Item item) {
      return item.isExpanded;
    },
    updateExpansionState: (Item item, bool expanded) {
      item.isExpanded = expanded;
    },
  );

  late final _treeController = TreeController<Item>(
    dataSource: _dataSource,
  );

  @override
  void dispose() {
    _treeController.dispose();
    super.dispose();
  }

  Widget _builder(BuildContext context, TreeNode<Item> node) {
    final label = node.item.label;
    final childCount = node.item.children.length;

    return TreeTile<Item>(
      node: node,
      guide: const IndentGuide.connectingLines(indent: 24, thickness: 1),
      onTap: () => _treeController.toggleItemExpansion(node.item),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('$label - Children: $childCount'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TreeView<Item>(
      controller: _treeController,
      builder: _builder,
    );
  }
}
