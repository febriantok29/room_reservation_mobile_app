class ReservationCreateRequest {
  String? roomId;
  DateTime? startTime;
  DateTime? endTime;
  String? purpose;
  int visitorCount;

  ReservationCreateRequest({
    this.roomId,
    this.startTime,
    this.endTime,
    this.purpose,
    this.visitorCount = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'purpose': purpose,
      'visitorCount': visitorCount,
    };
  }

  void validate() {
    if (roomId == null || roomId!.isEmpty) {
      throw 'ID ruangan wajib diisi';
    }

    if (startTime == null) {
      throw 'Waktu mulai wajib diisi';
    }

    if (endTime == null) {
      throw 'Waktu selesai wajib diisi';
    }

    if (purpose == null || purpose!.trim().isEmpty) {
      throw 'Tujuan reservasi wajib diisi';
    }

    if (visitorCount < 1) {
      throw 'Jumlah pengunjung minimal 1 orang';
    }
  }
}
