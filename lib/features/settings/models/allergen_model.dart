class AllergenModel {
  final String id;
  final String slug;
  final String labelFr;
  final String labelEn;

  const AllergenModel({
    required this.id,
    required this.slug,
    required this.labelFr,
    required this.labelEn,
  });

  String get label => labelFr;

  factory AllergenModel.fromJson(Map<String, dynamic> json) {
    return AllergenModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      labelFr: json['label_fr'] as String,
      labelEn: json['label_en'] as String,
    );
  }
}
