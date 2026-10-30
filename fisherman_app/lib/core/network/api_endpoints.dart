class ApiEndpoints {
  static const String health = '/health';

  // Auth
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';
  static const String me = '/api/auth/me';
  static const String profile = '/api/auth/profile';
  static String userProfile(int id) => '/api/users/$id';

  // Spots
  static const String spots = '/api/spots';
  static String spotDetail(int id) => '/api/spots/$id';
  static String toggleFavorite(int id) => '/api/spots/$id/favorite';
  static const String myFavorites = '/api/my/favorites';
  static String spotReviews(int id) => '/api/spots/$id/reviews';
  static String deleteSpot(int id) => '/api/spots/$id';
  static String updateSpot(int id) => '/api/spots/$id';

  // Catches
  static const String catches = '/api/catches';
  static String catchDetail(int id) => '/api/catches/$id';
  static String toggleLike(int id) => '/api/catches/$id/like';
  static String addComment(int id) => '/api/catches/$id/comments';
  static String deleteCatch(int id) => '/api/catches/$id';
  static String updateCatch(int id) => '/api/catches/$id';
  static String deleteComment(int catchId, int commentId) =>
      '/api/catches/$catchId/comments/$commentId';

  // Follow
  static String toggleFollow(int userId) => '/api/users/$userId/follow';
  static String followers(int userId) => '/api/users/$userId/followers';
  static String following(int userId) => '/api/users/$userId/following';

  // Notifications
  static const String notifications = '/api/notifications';
  static const String notificationsRead = '/api/notifications/read';
  static const String notificationsUnreadCount =
      '/api/notifications/unread-count';

  // Search
  static const String search = '/api/search';

  // Stats
  static const String stats = '/api/stats';
  static const String myStats = '/api/stats/my';

  // Weather
  static const String weather = '/api/weather';

  // Upload
  static const String upload = '/api/upload';
}
