// TODO: Update this to not dumb code...
// Example here.
/*
  
enum Phase {
  red,
  white,
  blue,
}

void main() {
  final circuits = List<int>.generate(96, (index) => index + 1);
  
  
  final result = circuits.map((circuit) => '$circuit : ${detectPhase(circuit)}').join("\n");
  
  print(result);
 
}

Phase detectPhase(int patchNumber) {
  final remainder = patchNumber % 3;
  
  return switch(remainder) {
      1 => Phase.red,
      2 => Phase.white,
      0 => Phase.blue,
      _ => throw "Unknown"
  };
}
*/

int getPhaseFromIndex(int index) {
  return switch (index) {
    0 => 1,
    1 => 2,
    2 => 3,
    3 => 1,
    4 => 2,
    5 => 3,
    _ => _dumbSearch(index + 1)
  };
}

int _dumbSearch(int outletNumber) {
  return _generatePhaseNumbers(outletNumber);
}

int _generatePhaseNumbers(int outletNumber) {
  int? lastPhase;
  final phases = List<int>.generate(outletNumber, (index) {
    if (lastPhase == null) {
      lastPhase = 1;
      return 1;
    }

    if (lastPhase == 1) {
      lastPhase = 2;
      return 2;
    }

    if (lastPhase == 2) {
      lastPhase = 3;
      return 3;
    }

    if (lastPhase == 3) {
      lastPhase = 1;
      return 1;
    }

    return 1;
  });

  return phases.last;
}
