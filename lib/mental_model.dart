import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class MentalModel extends StatefulWidget {
  const MentalModel({super.key});

  @override
  State<MentalModel> createState() => _MentalModelState();
}

class _MentalModelState extends State<MentalModel> {
  late final GlobalKey _paintKey;
  late final TransformationController _controller;
  Uint8List? _imageData;
  bool mentalModelBuilding = false;
  Rect? _viewportRect;
  final Size _childSize = const Size(1000, 1000);
  final Size _miniSize = const Size(100, 100);

  @override
  void initState() {
    super.initState();
    _paintKey = GlobalKey();
    _controller = TransformationController();
    WidgetsBinding.instance.addPostFrameCallback((_) => mentalModelObject());
  }

  Future<void> mentalModelObject() async {
    if (mentalModelBuilding) return;
    mentalModelBuilding = true;
    final renderBox = _paintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await renderBox.toImage(pixelRatio: 1 / 4);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) return;
    _imageData = byteData.buffer.asUint8List();
    setState(() {});
    mentalModelBuilding = false;
  }

  Color generateRandomMaterialColor() {
    final math.Random random = math.Random();
    return Colors.primaries[random.nextInt(Colors.primaries.length)];
  }

  Rect computeVisibleRect({required Size childSize, required Size viewportSize, required Matrix4 matrix}) {
    final scale = matrix.getMaxScaleOnAxis();

    final translation = matrix.getTranslation();
    final dx = -translation.x / scale;
    final dy = -translation.y / scale;

    final visibleWidth = viewportSize.width / scale;
    final visibleHeight = viewportSize.height / scale;

    return Rect.fromLTWH(dx, dy, visibleWidth, visibleHeight).intersect(Offset.zero & childSize);
  }

  // miniSize -> minimap size
  Rect mapToMinimap(Rect worldRect, Size childSize, Size miniSize) {
    final scaleX = miniSize.width / childSize.width;
    final scaleY = miniSize.height / childSize.height;

    return Rect.fromLTWH(worldRect.left * scaleX, worldRect.top * scaleY, worldRect.width * scaleX, worldRect.height * scaleY);
  }

  void _updateViewportRect(Size viewportSize) {
    final worldRect = computeVisibleRect(childSize: _childSize, viewportSize: viewportSize, matrix: _controller.value);

    _viewportRect = mapToMinimap(worldRect, _childSize, _miniSize);

    setState(() {});
  }

  void _onMinimapDrag(Offset delta) {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mental Model"),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(100),
          child: _imageData != null
              ? Align(
                  alignment: .centerRight,
                  child: Stack(
                    children: [
                      Image.memory(_imageData!, width: 100, height: 100),
                      if (_viewportRect != null)
                        Positioned.fromRect(
                          rect: _viewportRect!,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              _onMinimapDrag(details.delta);
                            },
                            child: Container(
                              decoration: BoxDecoration(border: Border.all(color: Colors.red, width: 2)),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : SizedBox.shrink(),
        ),
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return InteractiveViewer(
              transformationController: _controller,
              minScale: .5,
              maxScale: 12,
              constrained: false,
              onInteractionUpdate: (_) => _updateViewportRect(constraints.biggest),
              child: RepaintBoundary(key: _paintKey, child: FlutterLogo(size: 1000)),
            );
          },
        ),
      ),
    );
  }
}
