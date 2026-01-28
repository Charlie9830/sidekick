import 'dart:collection';

import 'package:collection/collection.dart';

///
/// Special purpose list that allows for specific logic when inserting items
/// Spots (aka slots) in this list can have null content, which flags them as empty, allowing for
/// items to be inserted in their place, whilst occupied items are shifted down the list.
///
class PackableList<T> extends Iterable {
  List<IndexedSpot<T>> _state;

  PackableList._internal(Iterable<IndexedSpot<T>> items, int maxIndex)
      : _state = _expand(items, maxIndex);

  factory PackableList.fromIndexedSpots(
      Iterable<IndexedSpot<T>> spots, int maxIndex) {
    return PackableList._internal(spots, maxIndex);
  }

  void insert(Iterable<T> items, int insertIndex) {
    _state = _packInsert(_state, items, insertIndex);
  }

  List<T?> toValueList() {
    return _state.map((spot) => spot.content).toList();
  }

  List<IndexedSpot<T>> toIndexedSpotList() {
    return _state.toList();
  }

  static List<IndexedSpot<T>> _expand<T>(
      Iterable<IndexedSpot<T>> slots, int maxIndex) {
    final slotsByIndex = Map<int, IndexedSpot<T>>.fromEntries(
        slots.map((slot) => MapEntry(slot.index, slot)));

    return List<IndexedSpot<T>>.generate(maxIndex, (index) {
      return slotsByIndex[index] ?? IndexedSpot<T>(index, null);
    });
  }

  List<IndexedSpot<T>> _packInsert<T>(
      List<IndexedSpot<T>> slots, Iterable<T?> incoming, int insertIndex) {
    final slotValues = slots.map((slot) => slot.content).toList();
    final targetRange = slotValues.sublist(insertIndex);
    final recursionResult = _recursiveInsert(
        _SlotRecursionValue.initial(incoming.toList(), targetRange));

    return [
      ...slotValues.sublist(0, insertIndex),
      ...recursionResult.accumulator,
    ].mapIndexed((index, value) => IndexedSpot<T>(index, value)).toList();
  }

  _SlotRecursionValue _recursiveInsert(_SlotRecursionValue current) {
    if (current.existingSlotContents.isEmpty &&
        current.incomingValues.isEmpty &&
        current.carry.isEmpty) {
      return current;
    }

    // Represents the slot we are currently looking at, this slot could be empty, or have existing data in it.
    final targetSlotContents = current.existingSlotContents.isNotEmpty
        ? current.existingSlotContents.removeFirst()
        : null;

    if (current.incomingValues.isNotEmpty) {
      // We still need to insert values from the incoming pile.
      if (targetSlotContents == null) {
        // Vacant Slot, insert the incoming into this slot.
        return _recursiveInsert(current.copyWith(
          accumulator: [
            ...current.accumulator,
            current.incomingValues.removeFirst(),
          ],
        ));
      } else {
        // Occupied Slot, capture it's current contents and carry them.
        return _recursiveInsert(current.copyWith(accumulator: [
          ...current.accumulator,
          current.incomingValues.removeFirst(),
        ], carry: current.carry..add(targetSlotContents)));
      }
    }

    if (current.carry.isNotEmpty) {
      // Incoming Pile is exhausted, but we still have items in the carry pile.
      if (targetSlotContents == null) {
        // Vacant Slot, insert the current carried item.
        return _recursiveInsert(current.copyWith(
          accumulator: [
            ...current.accumulator,
            current.carry.removeFirst(),
          ],
        ));
      } else {
        // Occupied Slot, take the item currently in the slot and add it to the end of the carry queue, then insert
        // the item at the front of the carry queue into the slot.

        // Be Careful of the order of operations here. Remove the front of the carry queue, then add the item in the
        // target slot to the back of the queue.
        final valueGettingInserted = current.carry.removeFirst();
        final carry = current.carry..add(targetSlotContents);
        return _recursiveInsert(current.copyWith(
          accumulator: [...current.accumulator, valueGettingInserted],
          carry: carry,
        ));
      }
    }

    if (current.existingSlotContents.isNotEmpty) {
      // Since we have exhausted the incomingValues and the Carry, it does not matter if this slot is vacant or occupied,
      // in reality it's contents dont mean anything, we just need to append them to the Accumulator so they dont get
      // lost.
      return _recursiveInsert(current.copyWith(accumulator: [
        ...current.accumulator,
        targetSlotContents,
      ]));
    }

    return current;
  }

  @override
  Iterator<IndexedSpot<T>> get iterator => _state.iterator;
}

class IndexedSpot<T> {
  final int index;
  final T? content;

  IndexedSpot(this.index, this.content);
}

class _SlotRecursionValue<T> {
  final List<T?> accumulator;
  final Queue<T> incomingValues;
  final Queue<T> carry;
  final Queue<T?> existingSlotContents;

  _SlotRecursionValue({
    required this.accumulator,
    required this.incomingValues,
    required this.carry,
    required this.existingSlotContents,
  });

  factory _SlotRecursionValue.initial(
    List<T?> incomingValues,
    List<T?> existingSlotContents,
  ) {
    return _SlotRecursionValue<T>(
        accumulator: <T>[],
        incomingValues: Queue<T>.from(incomingValues),
        carry: Queue<T>(),
        existingSlotContents: Queue<T>.from(existingSlotContents));
  }

  _SlotRecursionValue<T> copyWith({
    List<T?>? accumulator,
    Queue<T>? incomingValues,
    Queue<T>? carry,
    Queue<T?>? existingSlotContents,
  }) {
    return _SlotRecursionValue<T>(
      accumulator: accumulator ?? this.accumulator,
      incomingValues: incomingValues ?? this.incomingValues,
      carry: carry ?? this.carry,
      existingSlotContents: existingSlotContents ?? this.existingSlotContents,
    );
  }
}
