class RawLocationModel {
  final String generatedId;
  final String mvrId;
  final String name;

  RawLocationModel({
    required this.generatedId,
    required this.mvrId,
    required this.name,
  });

  const RawLocationModel.none()
      : generatedId = '',
        mvrId = '',
        name = '';
}
