int getMultiPatchFromIndex(int index) {
  final circuitNumber = (index + 1) % 6;

  if (circuitNumber == 0) {
    return 6;
  }

  return circuitNumber;
}
