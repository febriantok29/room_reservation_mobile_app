import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:room_reservation_mobile_app/app/models/meta_data_response.dart';
import 'package:room_reservation_mobile_app/app/models/room.dart';
import 'package:room_reservation_mobile_app/app/repositories/room_repository.dart';

class RoomSelectorPage extends StatefulWidget {
  final DateTime startDate;
  final DateTime endDate;

  const RoomSelectorPage({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<RoomSelectorPage> createState() => _RoomSelectorPageState();
}

class _RoomSelectorPageState extends State<RoomSelectorPage> {
  final _dateFormatter = DateFormat('EEEE, dd MMM yyyy', 'id_ID');
  final _roomRepository = RoomRepository.getInstance();
  final _scrollController = ScrollController();

  late DateTime _startDate;
  late DateTime _endDate;

  // For infinite scrolling
  final List<Room> _rooms = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasReachedEnd = false;
  MetaDataResponse? _metadata;

  // Stream subscription
  StreamSubscription<({List<Room> rooms, MetaDataResponse metadata})>?
  _streamSubscription;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;

    // Setup scroll listener for infinite scrolling
    _scrollController.addListener(_onScroll);

    // Start fetching data
    _setupRoomStream();
  }

  void _setupRoomStream() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _rooms.clear();
      _metadata = null;
    });

    // Reset repository and start loading data
    _roomRepository.refresh();
    _loadInitialData();

    // Subscribe to stream
    _streamSubscription?.cancel();
    _streamSubscription = _roomRepository.roomsStream.listen(
      (data) {
        setState(() {
          _isLoading = false;
          _rooms.clear();
          _rooms.addAll(data.rooms);
          _metadata = data.metadata;
          _hasReachedEnd = !(_metadata?.hasNextPage ?? false);
        });
      },
      onError: (error) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = error.toString();
        });
      },
    );
  }

  Future<void> _loadInitialData() async {
    await _roomRepository.loadMoreRooms(start: _startDate, end: _endDate);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        !_hasReachedEnd) {
      // Load more data as we're approaching the end of the list
      _loadMoreData();
    }
  }

  void _loadMoreData() {
    if (!_roomRepository.isLoading && (_metadata?.hasNextPage ?? true)) {
      _roomRepository.loadMoreRooms();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Ruangan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jadwal Reservasi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Tanggal: ${_dateFormatter.format(_startDate)}'),
                    Text(
                      'Waktu: ${TimeOfDay.fromDateTime(_startDate).format(context)} - ${TimeOfDay.fromDateTime(_endDate).format(context)}',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _buildRoomList()),
        ],
      ),
    );
  }

  Widget _buildRoomList() {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _setupRoomStream,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_rooms.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rooms.isEmpty && !_isLoading) {
      return const Center(child: Text('Tidak ada ruangan yang tersedia'));
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            _setupRoomStream();
          },
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _rooms.length + (_hasReachedEnd ? 0 : 1),
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              if (index == _rooms.length) {
                return _isLoading || _roomRepository.isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox.shrink();
              }

              final room = _rooms[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(room.name ?? 'Unknown Room'),
                  subtitle: Text(room.description ?? 'No description'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pop(context, room);
                  },
                ),
              );
            },
          ),
        ),
        if (_roomRepository.isLoading && _rooms.isNotEmpty)
          const Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }
}
