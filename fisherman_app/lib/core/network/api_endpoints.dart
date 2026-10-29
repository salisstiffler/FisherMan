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

  // Catches
  static const String catches = '/api/catches';
  static String catchDetail(int id) => '/api/catches/$id';
  static String toggleLike(int id) => '/api/catches/$id/like';
  static String addComment(int id) => '/api/catches/$id/comments';

  // Weather & Stats
  static const String weather = '/api/weather';
  static const String stats = '/api/stats';
}
