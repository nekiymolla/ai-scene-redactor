abstract final class AppRoutes {
  static const home = '/';
  static const settings = '/settings';

  // Creation wizard, nested so every step keeps the draft alive.
  static const create = '/create';
  static const createCharacters = '/create/characters';
  static const createDescribe = '/create/describe';
  static const createReview = '/create/review';

  static String project(String id) => '/projects/$id';
}
