import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/floor_room_models.dart';

class FloorEditorScreen extends ConsumerStatefulWidget {
  final String interviewId;
  final FloorModel? floor; // null = nowa kondygnacja

  const FloorEditorScreen({
    super.key,
    required this.interviewId,
    this.floor,
  });

  @override
  ConsumerState<FloorEditorScreen> createState() => _FloorEditorScreenState();
}

class _FloorEditorScreenState extends ConsumerState<FloorEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late FloorType _selectedType;
  late TextEditingController _areaController;
  late TextEditingController _heightController;
  List<RoomModel> _rooms = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.floor?.type ?? FloorType.groundFloor;
    _areaController = TextEditingController(text: widget.floor?.area.toString() ?? '');
    _heightController = TextEditingController(text: widget.floor?.height.toString() ?? '');
    _rooms = List.from(widget.floor?.rooms ?? []);
  }

  @override
  void dispose() {
    _areaController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _addRoom() async {
    final room = await Navigator.push<RoomModel>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomEditorDialog(),
      ),
    );

    if (room != null && mounted) {
      setState(() {
        _rooms.add(room);
      });
    }
  }

  void _editRoom(int index) async {
    final room = await Navigator.push<RoomModel>(
      context,
      MaterialPageRoute(
        builder: (_) => RoomEditorDialog(room: _rooms[index]),
      ),
    );

    if (room != null && mounted) {
      setState(() {
        _rooms[index] = room;
      });
    }
  }

  void _deleteRoom(int index) {
    setState(() {
      _rooms.removeAt(index);
    });
  }

  void _saveFloor() {
    if (!_formKey.currentState!.validate()) return;

    final floor = FloorModel(
      id: widget.floor?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      area: double.tryParse(_areaController.text) ?? 0,
      height: double.tryParse(_heightController.text) ?? 0,
      rooms: _rooms,
    );

    Navigator.pop(context, floor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.floor == null ? 'Nowa kondygnacja' : 'Edytuj kondygnację'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveFloor,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Floor info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dane kondygnacji',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FloorType>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Typ kondygnacji *',
                        prefixIcon: Icon(Icons.layers),
                        border: OutlineInputBorder(),
                      ),
                      items: FloorType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                      validator: (v) => v == null ? 'Wymagane' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _areaController,
                            decoration: const InputDecoration(
                              labelText: 'Powierzchnia *',
                              suffixText: 'm²',
                              prefixIcon: Icon(Icons.square_foot),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _heightController,
                            decoration: const InputDecoration(
                              labelText: 'Wysokość *',
                              suffixText: 'm',
                              prefixIcon: Icon(Icons.height),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Rooms section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pomieszczenia (${_rooms.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: _addRoom,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_rooms.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(Icons.meeting_room, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Brak pomieszczeń',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _addRoom,
                                icon: const Icon(Icons.add),
                                label: const Text('Dodaj pomieszczenie'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _rooms.length,
                        itemBuilder: (context, index) {
                          final room = _rooms[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Text(room.name),
                              subtitle: Text('${room.area} m²${room.heated ? " • ogrzewane" : ""}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _editRoom(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                    onPressed: () => _deleteRoom(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saveFloor,
                icon: const Icon(Icons.save),
                label: const Text('Zapisz kondygnację'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Room Editor Dialog
class RoomEditorDialog extends StatefulWidget {
  final RoomModel? room;

  const RoomEditorDialog({super.key, this.room});

  @override
  State<RoomEditorDialog> createState() => _RoomEditorDialogState();
}

class _RoomEditorDialogState extends State<RoomEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _areaController;
  bool _heated = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room?.name ?? '');
    _areaController = TextEditingController(text: widget.room?.area.toString() ?? '');
    _heated = widget.room?.heated ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final room = RoomModel(
      id: widget.room?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      area: double.tryParse(_areaController.text) ?? 0,
      heated: _heated,
    );

    Navigator.pop(context, room);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.room == null ? 'Nowe pomieszczenie' : 'Edytuj pomieszczenie'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nazwa pomieszczenia *',
                hintText: 'np. Salon, Kuchnia, Sypialnia',
                prefixIcon: Icon(Icons.meeting_room),
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                labelText: 'Powierzchnia *',
                suffixText: 'm²',
                prefixIcon: Icon(Icons.square_foot),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Pomieszczenie ogrzewane'),
              value: _heated,
              onChanged: (value) => setState(() => _heated = value),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.check),
                label: const Text('Zapisz pomieszczenie'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
