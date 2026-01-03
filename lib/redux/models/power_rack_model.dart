// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:sidekick/model_collection/model_collection_member.dart';
import 'package:sidekick/redux/models/power_rack_template_model.dart';
import 'package:sidekick/utils/get_uid.dart';

class PowerRackModel extends ModelCollectionMember {
  @override
  final String uid;
  final String name;
  final String notes;
  final String parentSystemId;
  final String parentFeedId;
  final int rackIndex;
  final int desiredSpareOutlets;
  final OutletCollection outletSlots;

  PowerRackModel({
    required this.uid,
    required this.name,
    required this.notes,
    required this.parentSystemId,
    required this.parentFeedId,
    required this.rackIndex,
    this.desiredSpareOutlets = 0,
    required this.outletSlots,
  });

  factory PowerRackModel.fromTemplate(PowerRackTemplateModel template) {
    return PowerRackModel(
        uid: getUid(),
        name: template.name,
        notes: '',
        parentFeedId: '',
        parentSystemId: '',
        rackIndex: 0,
        outletSlots: OutletCollection.empty(
            qty: (template.ways / template.multiCount).floor()));
  }

  PowerRackModel withClearedOutlets() {
    return copyWith(
      outletSlots: OutletCollection.empty(qty: outletSlots.qty),
    );
  }

  PowerRackModel withOutlets(List<String> newOutletIds) {
    assert(
        newOutletIds.length - desiredSpareOutlets <= outletSlots.qty,
        'Cannot add more Outlet ids then are available to PowerRackModel outletIds.\n'
        'Incoming new Outlet ids: ${newOutletIds.length}\n'
        'desiredSpareOutlets: $desiredSpareOutlets\noutletIds length: ${outletSlots.qty}');

    return copyWith(
        outletSlots: OutletCollection.fromIds(
            qty: outletSlots.qty, outletIds: newOutletIds));
  }

  PowerRackModel copyWith({
    String? uid,
    String? name,
    String? notes,
    String? parentSystemId,
    String? parentFeedId,
    int? rackIndex,
    int? desiredSpareOutlets,
    OutletCollection? outletSlots,
  }) {
    return PowerRackModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      parentSystemId: parentSystemId ?? this.parentSystemId,
      parentFeedId: parentFeedId ?? this.parentFeedId,
      rackIndex: rackIndex ?? this.rackIndex,
      desiredSpareOutlets: desiredSpareOutlets ?? this.desiredSpareOutlets,
      outletSlots: outletSlots ?? this.outletSlots,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'name': name,
      'notes': notes,
      'parentSystemId': parentSystemId,
      'parentFeedId': parentFeedId,
      'rackIndex': rackIndex,
      'desiredSpareOutlets': desiredSpareOutlets,
      'outletSlots': outletSlots.toMap(),
    };
  }

  factory PowerRackModel.fromMap(Map<String, dynamic> map) {
    return PowerRackModel(
        uid: map['uid'] as String,
        name: map['name'] as String,
        notes: map['notes'] as String,
        parentSystemId: map['parentSystemId'] as String,
        parentFeedId: map['parentFeedId'] as String,
        rackIndex: map['rackIndex'] as int,
        desiredSpareOutlets: map['desiredSpareOutlets'] as int,
        outletSlots: OutletCollection.fromMap(
            map['outletSlots'] ?? OutletCollection.empty(qty: 16)));
  }

  String toJson() => json.encode(toMap());

  factory PowerRackModel.fromJson(String source) =>
      PowerRackModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PowerRackModel(uid: $uid, name: $name, notes: $notes, parentSystemId: $parentSystemId, parentFeedId: $parentFeedId, rackIndex: $rackIndex, desiredSpareOutlets: $desiredSpareOutlets)';
  }
}

class OutletSlot {
  final int index;
  final String outletId;

  OutletSlot({
    required this.index,
    required this.outletId,
  });

  const OutletSlot.empty({required this.index}) : outletId = '';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'index': index,
      'outletId': outletId,
    };
  }

  factory OutletSlot.fromMap(Map<String, dynamic> map) {
    return OutletSlot(
      index: map['index'] as int,
      outletId: map['outletId'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory OutletSlot.fromJson(String source) =>
      OutletSlot.fromMap(json.decode(source) as Map<String, dynamic>);
}

class OutletCollection {
  final int qty;
  final List<OutletSlot> _slots;

  OutletCollection({
    required this.qty,
    required List<OutletSlot> slots,
  }) : _slots = slots;

  factory OutletCollection.fromIds(
      {required int qty, required List<String> outletIds}) {
    return OutletCollection(
        qty: qty,
        slots: List<OutletSlot>.generate(
            qty,
            (index) => OutletSlot(
                index: index,
                outletId: outletIds.elementAtOrNull(index) ?? '')));
  }

  factory OutletCollection.empty({required int qty}) {
    return OutletCollection(
        qty: qty,
        slots: List<OutletSlot>.generate(
            qty, (index) => OutletSlot(index: index, outletId: '')));
  }

  List<OutletSlot> get slots => _slots;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'qty': qty,
      'slots': _slots.map((x) => x.toMap()).toList(),
    };
  }

  factory OutletCollection.fromMap(Map<String, dynamic> map) {
    return OutletCollection(
      qty: map['qty'] as int,
      slots: List<OutletSlot>.from(
        (map['slots'] as List<int>).map<OutletSlot>(
          (x) => OutletSlot.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory OutletCollection.fromJson(String source) =>
      OutletCollection.fromMap(json.decode(source) as Map<String, dynamic>);
}
