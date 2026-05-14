# 分页配置统一说明

## 概述

本次更改统一了整个应用程序中的分页配置，实现了滚动到底部自动加载更多的功能，避免了硬编码并提供了集中化的配置管理。

## 核心功能

### 滚动到底部自动加载

- 用户滚动到距离底部 100px 时自动触发加载下一页
- 移除了下拉刷新功能，专注于向下滚动的体验
- 显示加载状态和"没有更多了"的提示

### 防重复加载机制

- 使用本地状态防止快速滚动时重复触发加载
- 只有在满足所有条件时才触发加载：
  - 滚动到触发距离
  - 有更多数据可加载
  - 当前没有在加载中
  - 已有聊天数据

## 配置文件

### `lib/config/pagination_config.dart`

这个配置文件包含了所有分页相关的常量：

```dart
class PaginationConfig {
  /// 默认页面大小 - 20条记录
  static const int defaultPageSize = 20;
  
  /// 搜索结果页面大小 - 20条记录  
  static const int searchPageSize = 20;
  
  /// 最大页面大小 - 100条记录
  static const int maxPageSize = 100;
  
  /// 最小页面大小 - 1条记录
  static const int minPageSize = 1;
  
  /// 滚动触发加载的距离 - 100像素
  static const double loadMoreTriggerDistance = 100.0;
}
```

## 用户体验流程

1. **初始加载**: 应用启动时自动加载第一页数据
2. **滚动浏览**: 用户向下滚动查看聊天历史
3. **自动加载**: 接近底部时自动加载下一页，显示加载指示器
4. **无缝体验**: 新数据追加到列表末尾，用户可继续滚动
5. **结束提示**: 没有更多数据时显示"—— 没有更多了 ——"

## 技术实现

### 页码约定

- **页码从 1 开始**: 符合常规分页概念，第一页为 page=1
- **内部转换**: 本地存储层自动转换为从 0 开始的 offset 计算
- **API 统一**: 所有 Repository 接口使用 1-based 页码

```dart
// 用户调用 (1-based)
final result = await repository.getChats(page: 1); // 第一页

// 内部转换 (0-based offset)
final offset = (page - 1) * pageSize; // offset = 0 for first page
```

### ScrollController 监听

```dart
void _scrollListener() {
  final scrollPosition = _scrollController.position;
  final isNearBottom = scrollPosition.pixels >= 
      scrollPosition.maxScrollExtent - PaginationConfig.loadMoreTriggerDistance;
  
  if (isNearBottom && hasMoreData && !isLoading) {
    loadMoreChats();
  }
}
```

### 状态管理

- `_currentPage`: 当前页码 (从 1 开始)
- `hasMoreChats`: 是否还有更多数据
- `isLoadingChats`: 是否正在加载
- `_isLoadingMore`: 本地防重复加载标志

### UI 状态显示

- **加载中**: 转圈动画 + "正在下载数据..."
- **没有更多**: "—— 没有更多了 ——"
- **有更多**: 显示足够的空白区域供滚动检测

## 主要优势

1. **自然体验**: 符合用户滚动浏览的习惯
2. **性能优化**: 按需加载，避免一次性加载大量数据
3. **防误触**: 精确的触发距离和防重复机制
4. **状态清晰**: 明确的加载状态和结束提示
5. **配置统一**: 所有分页参数集中管理

## 配置说明

- **loadMoreTriggerDistance**: 100px 是经过测试的最佳触发距离，既不会太早触发，也不会让用户等待
- **defaultPageSize**: 20条记录平衡了网络请求效率和用户体验
- **footer 高度**: 50px 确保有足够空间进行滚动检测

## 与搜索功能的配合

搜索时会重置分页状态，新的搜索结果同样支持滚动加载更多功能，提供一致的用户体验。