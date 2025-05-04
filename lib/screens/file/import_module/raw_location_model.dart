class RawLocationModel {
  final String mvrId;
  final String generatedId;
  final String name;

  RawLocationModel({
    required this.mvrId,
    required this.generatedId,
    required this.name,
  });

  const RawLocationModel.none()
      : mvrId = '',
        generatedId = '',
        name = '';
}
