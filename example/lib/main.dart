import 'dart:math';

import 'package:flutter/material.dart';

import 'pages/basic_flexbox_page.dart';
import 'pages/cat_gallery_page.dart';
import 'pages/delegates_showcase_page.dart';
import 'pages/dynamic_flexbox_list_page.dart';
import 'pages/dynamic_flexbox_page.dart';
import 'pages/network_image_gallery_page.dart';
import 'pages/playground_page.dart';
import 'pages/sliver_flexbox_page.dart';
import 'theme/neo_brutalism.dart';

void main() {
  runApp(const FlexboxExampleApp());
}

class FlexboxExampleApp extends StatelessWidget {
  const FlexboxExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flexbox',
      debugShowCheckedModeBanner: false,
      theme: NeoBrutalism.themeData(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const List<_ExampleItem> _examples = [
    _ExampleItem(
      title: 'Basic Flexbox',
      subtitle: 'Flexbox properties playground',
      icon: Icons.grid_view_rounded,
      color: NeoBrutalism.yellow,
      page: BasicFlexboxPage(),
    ),
    _ExampleItem(
      title: 'Cat Gallery',
      subtitle: 'Local images with aspect ratios',
      icon: Icons.pets_rounded,
      color: NeoBrutalism.pink,
      page: CatGalleryPage(),
    ),
    _ExampleItem(
      title: 'Sliver Flexbox',
      subtitle: 'CustomScrollView integration',
      icon: Icons.view_agenda_rounded,
      color: NeoBrutalism.green,
      page: SliverFlexboxPage(),
    ),
    _ExampleItem(
      title: 'Network Gallery',
      subtitle: 'API-resolved image dimensions',
      icon: Icons.cloud_download_rounded,
      color: NeoBrutalism.blue,
      page: NetworkImageGalleryPage(),
    ),
    _ExampleItem(
      title: 'Dynamic Flexbox',
      subtitle: 'Auto-measuring sliver layout',
      icon: Icons.auto_fix_high_rounded,
      color: NeoBrutalism.purple,
      page: DynamicFlexboxPage(),
    ),
    _ExampleItem(
      title: 'Flexbox List',
      subtitle: 'Non-sliver convenience widget',
      icon: Icons.view_list_rounded,
      color: NeoBrutalism.orange,
      page: DynamicFlexboxListPage(),
    ),
    _ExampleItem(
      title: 'Delegates',
      subtitle: 'All delegate types showcase',
      icon: Icons.dashboard_rounded,
      color: NeoBrutalism.cyan,
      page: DelegatesShowcasePage(),
    ),
    _ExampleItem(
      title: 'Playground',
      subtitle: 'Interactive configuration',
      icon: Icons.science_rounded,
      color: NeoBrutalism.red,
      page: PlaygroundPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                color: NeoBrutalism.yellow,
                border: Border(
                  bottom: BorderSide(
                    color: NeoBrutalism.black,
                    width: NeoBrutalism.borderWidth,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: NeoBrutalism.shapeDecoration(
                      color: NeoBrutalism.black,
                      hasShadow: false,
                    ),
                    child: const Text(
                      'FLUTTER PACKAGE',
                      style: TextStyle(
                        color: NeoBrutalism.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(right: 4, bottom: 4),
                    decoration: NeoBrutalism.shapeDecoration(
                      color: NeoBrutalism.pink,
                      hasShadow: true,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: NeoBrutalism.shapeDecoration(
                              color: NeoBrutalism.white,
                              radius: 12,
                              hasShadow: false,
                            ),
                            child: Transform.rotate(
                              angle: pi / 2,
                              child: Icon(Icons.dashboard_rounded, size: 22),
                            ),
                          ),
                          Text(
                            'Flexbox',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'CSS Flexbox layout for Flutter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: NeoBrutalism.black.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = _examples[index];
                return _ExampleCard(item: item);
              }, childCount: _examples.length),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 140,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _ExampleItem {
  const _ExampleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;
}

class _ExampleCard extends StatefulWidget {
  const _ExampleCard({required this.item});

  final _ExampleItem item;

  @override
  State<_ExampleCard> createState() => _ExampleCardState();
}

class _ExampleCardState extends State<_ExampleCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => widget.item.page),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.translationValues(
          _isPressed ? NeoBrutalism.shadowOffset.dx : 0,
          _isPressed ? NeoBrutalism.shadowOffset.dy : 0,
          0,
        ),
        decoration: NeoBrutalism.shapeDecoration(
          color: widget.item.color,
          hasShadow: !_isPressed,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: NeoBrutalism.shapeDecoration(
                      color: NeoBrutalism.white,
                      radius: 8,
                      hasShadow: false,
                    ),
                    child: Icon(widget.item.icon, size: 22),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: NeoBrutalism.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                widget.item.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                widget.item.subtitle,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: NeoBrutalism.black.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
