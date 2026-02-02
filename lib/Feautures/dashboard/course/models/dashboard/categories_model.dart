import 'dart:ui';

class DashboardCategoriesModel {
  final String id; // Unique identifier for backend linking (FR15: modularity)
  final String title;
  final String heading;
  final String subHeading;
  final VoidCallback? onPress;

  DashboardCategoriesModel({
    required this.id,
    required this.title,
    required this.heading,
    required this.subHeading,
    this.onPress,
  });

  static List<DashboardCategoriesModel> list = [
    DashboardCategoriesModel(
      id: "js",
      title: "JS",
      heading: "JavaScript",
      subHeading: "10 Lessons",
      onPress: null,
    ),
    DashboardCategoriesModel(
      id: "fl",
      title: "F",
      heading: "Flutter",
      subHeading: "11 Lessons",
      onPress: null,
    ),
    DashboardCategoriesModel(
      id: "html",
      title: "H",
      heading: "HTML",
      subHeading: "8 Lessons",
      onPress: null,
    ),
    DashboardCategoriesModel(
      id: "kt",
      title: "K",
      heading: "Kotlin",
      subHeading: "20 Lessons",
      onPress: null,
    ),
    DashboardCategoriesModel(
      id: "py",
      title: "P",
      heading: "Python",
      subHeading: "100 Lessons",
      onPress: null,
    ),
  ];
}
