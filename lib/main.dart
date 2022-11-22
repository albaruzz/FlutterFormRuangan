// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'sql_helper.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the debug banner
        debugShowCheckedModeBanner: false,
        title: 'Ruangan FSM',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _validateNama = false;
  bool _validateKapasitas = false;
  // All Rooms
  List<Map<String, dynamic>> _Rooms = [];

  bool _isLoading = true;
  // This function is used to fetch all data from the database
  void _refreshRooms() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _Rooms = data;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kapasitasController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _refreshRooms(); // Loading the diary when the app starts
  }

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _kapasitasController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingRoom =
      _Rooms.firstWhere((element) => element['id'] == id);
      _namaController.text = existingRoom['nama'];
      _kapasitasController.text = existingRoom['kapasitas'];
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
          padding: EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            // this will prevent the soft keyboard from covering the text fields
            bottom: MediaQuery.of(context).viewInsets.bottom + 120,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _namaController,
                decoration: InputDecoration(
                    errorText: _validateNama ? 'Field tidak bolah kosong' : null,
                    hintText: 'Nama'),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                controller: _kapasitasController,
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                    errorText: _validateKapasitas ?  'Field tidak boleh kosong' : null,
                    hintText: 'Kapasitas'),
              ),
              const SizedBox(
                height: 0,
              ),
              ElevatedButton(
                onPressed: () async {
                  // Save new Room
                  if (id == null) {
                    _namaController.text.isEmpty ? _validateNama = true : _validateNama = false;
                    _kapasitasController.text.isEmpty ? _validateKapasitas = true : _validateKapasitas = false;
                    if (_validateNama == false && _validateKapasitas == false) {
                      await _addItem();
                    }
                  }

                  if (id != null) {
                    _namaController.text.isEmpty ? _validateNama = true : _validateNama = false;
                    _kapasitasController.text.isEmpty ? _validateKapasitas = true : _validateKapasitas = false;
                    if(_validateNama == false && _validateKapasitas == false){
                      await _updateItem(id);
                    }
                  }

                  if(_namaController.text.isEmpty == false && _kapasitasController.text.isEmpty == false) {
                    // Clear the text fields
                    _namaController.text = '';
                    _kapasitasController.text = '';
                    // Close the bottom sheet
                    Navigator.of(context).pop();
                  }
                },
                child: Text(id == null ? 'Create New' : 'Update'),
              )
            ],
          ),
        ));
  }

// Insert a new Room to the database
  Future<void> _addItem() async {
    await SQLHelper.createItem(
        _namaController.text, _kapasitasController.text);
    _refreshRooms();
  }

  // Update an existing Room
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id, _namaController.text, _kapasitasController.text);
    _refreshRooms();
  }

  // Delete an item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a Room!'),
    ));
    _refreshRooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruangan FSM'),
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView.builder(
        itemCount: _Rooms.length,
        itemBuilder: (context, index) => Card(
          color: Colors.green[200],
          margin: const EdgeInsets.all(15),
          child: ListTile(
              title: Text(_Rooms[index]['nama']),
              subtitle: Text(_Rooms[index]['kapasitas']),
              trailing: SizedBox(
                width: 100,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        _validateKapasitas = false;
                        _validateNama = false;
                        _showForm(_Rooms[index]['id']);}
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: (){
                        //membuat dialog konfirmasi hapus
                        AlertDialog hapus = AlertDialog(
                          title: Text("Warning!!"),
                          content: Container(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                    "Yakin ingin menghapus data ${_Rooms[index]['nama']}?"
                                )
                              ],
                            ),
                          ),
                          //terdapat 2 button.
                          //jika ya maka jalankan _deleteKontak() dan tutup dialog
                          //jika tidak maka tutup dialog
                          actions: [
                            TextButton(
                                onPressed: (){
                                  _deleteItem(_Rooms[index]['id']);
                                  Navigator.pop(context);
                                },
                                child: Text("Ya")
                            ),
                            TextButton(
                              child: Text('Tidak'),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        );
                        showDialog(context: context, builder: (context) => hapus);
                      },
                    )
                  ],
                ),
              )),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          _validateKapasitas = false;
          _validateNama = false;
          _namaController.text = '';
          _kapasitasController.text = '';
          _showForm(null);
        }

      ),
    );
  }
}