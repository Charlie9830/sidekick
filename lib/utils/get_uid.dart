import 'package:uuid/uuid.dart';

String getUid() {
  const uuid = Uuid();

  return uuid.v1();
}
