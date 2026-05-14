/// Configuration constants for pagination across the application
///
/// This class centralizes all pagination-related configuration to ensure
/// consistency across different parts of the application.
class PaginationConfig {
  /// Default page size for chat list pagination
  /// Used in sidebar chat list, search results, and general chat loading
  static const int defaultPageSize = 20;

  /// Page size for search results
  /// Can be different from default if search results need different pagination
  static const int searchPageSize = 20;

  /// Maximum page size allowed for any pagination request
  /// Used as a safety limit and for loading all items when needed
  static const int maxPageSize = 100;

  /// Minimum page size allowed for any pagination request
  /// Used for validation and edge cases
  static const int minPageSize = 1;

  /// Distance from bottom (in pixels) to trigger load more in scroll views
  /// When user scrolls within this distance from bottom, next page loads automatically
  static const double loadMoreTriggerDistance = 100.0;

  /// Private constructor to prevent instantiation
  PaginationConfig._();
}
