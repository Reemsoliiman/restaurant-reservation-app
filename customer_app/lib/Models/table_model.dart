class TableModel {
  final String id;
  final int seats;
  final String label;
  final int tableIndex;

  TableModel({
    required this.id,
    required this.seats,
    required this.label,
    required this.tableIndex,
  });

  factory TableModel.fromMap(String id, Map<String, dynamic> map) {
    int parseIntSafe(Object? v) {
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 1;
      return 1;
    }

    return TableModel(
      id: id,
      seats: parseIntSafe(map['seats']),
      label: map['label']?.toString() ?? 'Table',
      tableIndex: parseIntSafe(map['tableIndex']),
    );
  }
}
