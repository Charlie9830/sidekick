///
/// A utility function to ease the process of providing selection indexes to [ItemSelectionListener] widgets.
/// Returns a closure, that when called will provide an index that enumerates on each subsequent call.
int Function() getItemSelectionIndexClosure({int startingIndex = 0}) {
  int selectionIndex = startingIndex;

  return () => selectionIndex++;
}
