enum TableStatus {
  available,
  occupied,
  reserved,
}

extension TableStatusX on TableStatus {
  String get label => switch (this) {
        TableStatus.available => 'Available',
        TableStatus.occupied => 'Occupied',
        TableStatus.reserved => 'Reserved',
      };
}
