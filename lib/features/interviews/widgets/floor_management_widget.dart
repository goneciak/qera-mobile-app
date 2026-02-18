import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/floor_room_models.dart';

class FloorManagementWidget extends ConsumerStatefulWidget {
  final List<FloorModel> floors;
  final Function(List<FloorModel>) onFloorsChanged;
  final bool readOnly;

  const FloorManagementWidget({
    Key? key,
    required this.floors,
    required this.onFloorsChanged,
    this.readOnly = false,
  }) : super(key: key);

  @override
  ConsumerState<FloorManagementWidget> createState() => _FloorManagementWidgetState();
}

class _FloorManagementWidgetState extends ConsumerState<FloorManagementWidget> {
  final _uuid = const Uuid();

  void _addFloor() {
    final newFloor = FloorModel(
      id: _uuid.v4(),
      type: FloorType.groundFloor,
      area: 0,
      height: 2.5,
      rooms: [],
    );

    widget.onFloorsChanged([...widget.floors, newFloor]);
  }

  void _removeFloor(String floorId) {
    widget.onFloorsChanged(
      widget.floors.where((f) => f.id != floorId).toList(),
    );
  }

  void _updateFloor(FloorModel updatedFloor) {
    widget.onFloorsChanged(
      widget.floors.map((f) => f.id == updatedFloor.id ? updatedFloor : f).toList(),
    );
  }

  void _addRoom(String floorId) {
    final floor = widget.floors.firstWhere((f) => f.id == floorId);
    final newRoom = RoomModel(
      id: _uuid.v4(),
      name: 'Pokój ${floor.rooms.length + 1}',
      area: 0,
      heated: true,
    );

    final updatedFloor = floor.copyWith(
      rooms: [...floor.rooms, newRoom],
    );

    _updateFloor(updatedFloor);
  }

  void _removeRoom(String floorId, String roomId) {
    final floor = widget.floors.firstWhere((f) => f.id == floorId);
    final updatedFloor = floor.copyWith(
      rooms: floor.rooms.where((r) => r.id != roomId).toList(),
    );
    _updateFloor(updatedFloor);
  }

  void _updateRoom(String floorId, RoomModel updatedRoom) {
    final floor = widget.floors.firstWhere((f) => f.id == floorId);
    final updatedFloor = floor.copyWith(
      rooms: floor.rooms.map((r) => r.id == updatedRoom.id ? updatedRoom : r).toList(),
    );
    _updateFloor(updatedFloor);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Summary
        if (widget.floors.isNotEmpty) _buildSummary(),
        const SizedBox(height: 16),

        // Floors list
        ...widget.floors.asMap().entries.map((entry) {
          return _FloorCard(
            floor: entry.value,
            index: entry.key,
            readOnly: widget.readOnly,
            onUpdate: _updateFloor,
            onDelete: () => _removeFloor(entry.value.id),
            onAddRoom: () => _addRoom(entry.value.id),
            onUpdateRoom: (room) => _updateRoom(entry.value.id, room),
            onDeleteRoom: (roomId) => _removeRoom(entry.value.id, roomId),
          );
        }).toList(),

        // Add floor button
        if (!widget.readOnly)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: OutlinedButton.icon(
              onPressed: _addFloor,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj kondygnację'),
            ),
          ),
      ],
    );
  }

  Widget _buildSummary() {
    final totalFloors = widget.floors.length;
    final totalHeatedRooms = widget.floors.fold<int>(
      0,
      (sum, floor) => sum + floor.heatedRoomsCount,
    );
    final totalHeatedArea = widget.floors.fold<double>(
      0.0,
      (sum, floor) => sum + floor.heatedArea,
    );

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Podsumowanie',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Kondygnacje: $totalFloors'),
            Text('Ogrzewane pomieszczenia: $totalHeatedRooms'),
            Text('Powierzchnia ogrzewana: ${totalHeatedArea.toStringAsFixed(1)} m²'),
          ],
        ),
      ),
    );
  }
}

class _FloorCard extends StatelessWidget {
  final FloorModel floor;
  final int index;
  final bool readOnly;
  final Function(FloorModel) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onAddRoom;
  final Function(RoomModel) onUpdateRoom;
  final Function(String) onDeleteRoom;

  const _FloorCard({
    required this.floor,
    required this.index,
    required this.readOnly,
    required this.onUpdate,
    required this.onDelete,
    required this.onAddRoom,
    required this.onUpdateRoom,
    required this.onDeleteRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text('${floor.type.displayName} (${floor.rooms.length} pokoi)'),
        subtitle: Text(
          'Powierzchnia: ${floor.area.toStringAsFixed(1)} m² | '
          'Wysokość: ${floor.height.toStringAsFixed(1)} m',
        ),
        trailing: !readOnly
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Floor properties
                if (!readOnly) ...[
                  DropdownButtonFormField<FloorType>(
                    value: floor.type,
                    decoration: const InputDecoration(labelText: 'Typ kondygnacji'),
                    items: FloorType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onUpdate(floor.copyWith(type: value));
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: floor.area.toString(),
                          decoration: const InputDecoration(labelText: 'Powierzchnia (m²)'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final area = double.tryParse(value) ?? 0;
                            onUpdate(floor.copyWith(area: area));
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: floor.height.toString(),
                          decoration: const InputDecoration(labelText: 'Wysokość (m)'),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final height = double.tryParse(value) ?? 2.5;
                            onUpdate(floor.copyWith(height: height));
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                ],

                // Rooms list
                const Text(
                  'Pomieszczenia:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...floor.rooms.map((room) {
                  return _RoomTile(
                    room: room,
                    readOnly: readOnly,
                    onUpdate: onUpdateRoom,
                    onDelete: () => onDeleteRoom(room.id),
                  );
                }).toList(),

                if (!readOnly)
                  TextButton.icon(
                    onPressed: onAddRoom,
                    icon: const Icon(Icons.add),
                    label: const Text('Dodaj pokój'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final RoomModel room;
  final bool readOnly;
  final Function(RoomModel) onUpdate;
  final VoidCallback onDelete;

  const _RoomTile({
    required this.room,
    required this.readOnly,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: room.heated ? Colors.orange.shade50 : Colors.grey.shade100,
      child: ListTile(
        title: Text(room.name),
        subtitle: Text('${room.area.toStringAsFixed(1)} m² | ${room.heated ? 'Ogrzewany' : 'Nieogrzewany'}'),
        trailing: !readOnly
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () {
                      // TODO: Open edit dialog
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
