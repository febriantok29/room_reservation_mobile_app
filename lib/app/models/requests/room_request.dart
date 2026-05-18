class RoomRequest {
  final String? name;
  final int? floor;
  final String? description;
  final int? capacity;
  final List<String>? facilityIds;
  final bool? isMaintenance;

  RoomRequest({
    this.name,
    this.floor,
    this.description,
    this.capacity,
    this.facilityIds,
    this.isMaintenance,
  });

  RoomRequest copyWith({
    String? name,
    int? floor,
    String? description,
    int? capacity,
    List<String>? facilityIds,
    bool? isMaintenance,
  }) {
    return RoomRequest(
      name: name ?? this.name,
      floor: floor ?? this.floor,
      description: description ?? this.description,
      capacity: capacity ?? this.capacity,
      facilityIds: facilityIds ?? this.facilityIds,
      isMaintenance: isMaintenance ?? this.isMaintenance,
    );
  }

  void validate() {
    if (name == null || name!.trim().isEmpty) {
      throw 'Nama ruangan tidak boleh kosong';
    }

    if (floor == null || floor! < 1 || floor! > 99) {
      throw 'Lantai harus berada dalam rentang 1-99';
    }

    if (capacity == null || capacity! < 1 || capacity! > 1000) {
      throw 'Kapasitas harus berada dalam rentang 1-1000';
    }

    if (name!.length > 100) {
      throw 'Nama ruangan maksimal 100 karakter';
    }

    if (description != null && description!.length > 1000) {
      throw 'Deskripsi maksimal 1000 karakter';
    }

    if (facilityIds != null && facilityIds!.length > 50) {
      throw 'Jumlah fasilitas maksimal 50';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'floor': floor,
      'description': description,
      'capacity': capacity,
      'facility_ids': facilityIds,
      'is_maintenance': isMaintenance,
    };
  }
}
