/// Round a number up to the nearest Multi count.
int roundUpToNearestMultiBreak(int count) {
  final multiOutletCount = count == 0 ? 0 : (count / 6).ceil();
  return multiOutletCount * 6;
}