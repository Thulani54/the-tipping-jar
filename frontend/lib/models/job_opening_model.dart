class JobOpeningModel {
  final int id;
  final String title;
  final String department;
  final String location;
  final String employmentType;
  final String description;
  final DateTime createdAt;

  const JobOpeningModel({
    required this.id,
    required this.title,
    required this.department,
    required this.location,
    required this.employmentType,
    required this.description,
    required this.createdAt,
  });

  factory JobOpeningModel.fromJson(Map<String, dynamic> j) => JobOpeningModel(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        department: j['department'] as String? ?? '',
        location: j['location'] as String? ?? 'Remote',
        employmentType: j['employment_type'] as String? ?? 'Full-time',
        description: j['description'] as String? ?? '',
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
