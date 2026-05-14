import 'package:flutter/material.dart';
import 'utils.dart';

class WidgetsToImage extends StatelessWidget {
  final Widget? child;
  final WidgetsToImageController controller;
  // 添加新的属性
  final bool captureAll;

  const WidgetsToImage({
    super.key,
    required this.child,
    required this.controller,
    this.captureAll = false, // 默认为false
  });

  @override
  Widget build(BuildContext context) {
    if (!captureAll) {
      return RepaintBoundary(key: controller.containerKey, child: child);
    }

    // 使用SingleChildScrollView包装，确保所有内容都被渲染
    return RepaintBoundary(
      key: controller.containerKey,
      child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: child),
    );
  }
}
