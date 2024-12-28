import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:uuid/uuid.dart';
import 'models/spinner_item.dart';
import 'models/spinner.dart';
import 'models/spinner_style.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spinner App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SpinnerScreen(),
    );
  }
}

class SpinnerScreen extends StatefulWidget {
  const SpinnerScreen({super.key});

  @override
  State<SpinnerScreen> createState() => _SpinnerScreenState();
}

class _SpinnerScreenState extends State<SpinnerScreen> {
  List<Spinner> spinners = [];
  bool isLoading = true;
  Spinner? currentSpinner;
  bool isSpinning = false;
  late final StreamController<int> _selected;
  final _uuid = const Uuid();

  List<SpinnerStyle> predefinedStyles = [
    SpinnerStyle(
      id: 'default',
      name: 'Default',
      backgroundColor: Colors.blue.shade100,
      borderColor: Colors.blue,
      borderWidth: 2,
      textColor: Colors.black,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    SpinnerStyle(
      id: 'dark',
      name: 'Dark Mode',
      backgroundColor: Colors.grey.shade800,
      borderColor: Colors.white,
      borderWidth: 2,
      textColor: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    SpinnerStyle(
      id: 'neon',
      name: 'Neon',
      backgroundColor: Colors.black,
      borderColor: Colors.greenAccent,
      borderWidth: 3,
      textColor: Colors.greenAccent,
      fontSize: 18,
      fontWeight: FontWeight.w900,
    ),
    SpinnerStyle(
      id: 'pastel',
      name: 'Pastel',
      backgroundColor: Colors.pink.shade50,
      borderColor: Colors.pink.shade200,
      borderWidth: 2,
      textColor: Colors.pink.shade900,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selected = StreamController<int>.broadcast();
    _loadSpinners();
  }

  Future<void> _loadSpinners() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final spinnersJson = prefs.getStringList('spinners');
      
      if (spinnersJson == null || spinnersJson.isEmpty) {
        // Create default coin flip spinner
        final defaultSpinner = Spinner(
          id: _uuid.v4(),
          name: 'Coin Flip',
          items: [
            SpinnerItem(
              id: _uuid.v4(),
              title: 'Heads',
              description: 'The coin landed on heads!',
            ),
            SpinnerItem(
              id: _uuid.v4(),
              title: 'Tails',
              description: 'The coin landed on tails!',
            ),
          ],
          style: predefinedStyles[0], // Use default style
        );
        spinners = [defaultSpinner];
        currentSpinner = defaultSpinner;
        _saveSpinners();
      } else {
        spinners = spinnersJson.map((spinnerStr) {
          try {
            return Spinner.fromJson(json.decode(spinnerStr) as Map<String, dynamic>);
          } catch (e) {
            print('Error loading spinner: $e');
            // Return a default spinner if loading fails
            return Spinner(
              id: _uuid.v4(),
              name: 'New Spinner',
              items: [
                SpinnerItem(
                  id: _uuid.v4(),
                  title: 'Item 1',
                  description: 'First item',
                ),
                SpinnerItem(
                  id: _uuid.v4(),
                  title: 'Item 2',
                  description: 'Second item',
                ),
              ],
              style: predefinedStyles[0],
            );
          }
        }).toList();
        
        currentSpinner = spinners.first;
      }
    } catch (e) {
      print('Error loading spinners: $e');
      // Create a default spinner if loading fails completely
      final defaultSpinner = Spinner(
        id: _uuid.v4(),
        name: 'Default Spinner',
        items: [
          SpinnerItem(
            id: _uuid.v4(),
            title: 'Item 1',
            description: 'First item',
          ),
          SpinnerItem(
            id: _uuid.v4(),
            title: 'Item 2',
            description: 'Second item',
          ),
        ],
        style: predefinedStyles[0],
      );
      spinners = [defaultSpinner];
      currentSpinner = defaultSpinner;
    }
    
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveSpinners() async {
    final prefs = await SharedPreferences.getInstance();
    final spinnersJson = spinners
        .map((spinner) => json.encode(spinner.toJson()))
        .toList();
    await prefs.setStringList('spinners', spinnersJson);
  }

  void _addSpinner() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Spinner'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Spinner Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final newSpinner = Spinner(
                  id: _uuid.v4(),
                  name: nameController.text,
                  items: [],
                  style: predefinedStyles[0], // Use default style
                );
                setState(() {
                  spinners.add(newSpinner);
                  currentSpinner = newSpinner;
                });
                _saveSpinners();
                Navigator.pop(context);
                _showAddItemDialog(); // Prompt to add first item
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _deleteSpinner(String id) {
    if (spinners.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: At least one spinner is required'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      spinners.removeWhere((spinner) => spinner.id == id);
      if (currentSpinner!.id == id) {
        currentSpinner = spinners.first;
      }
    });
    _saveSpinners();
  }

  void _editSpinner(Spinner spinner) {
    final nameController = TextEditingController(text: spinner.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Spinner'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Spinner Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  final index = spinners.indexWhere((s) => s.id == spinner.id);
                  spinners[index] = Spinner(
                    id: spinner.id,
                    name: nameController.text,
                    items: spinner.items,
                    style: spinner.style,
                  );
                  if (currentSpinner!.id == spinner.id) {
                    currentSpinner = spinners[index];
                  }
                });
                _saveSpinners();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addItem(String title, String description) {
    setState(() {
      final newItem = SpinnerItem(
        id: _uuid.v4(),
        title: title,
        description: description,
      );
      final index = spinners.indexWhere((s) => s.id == currentSpinner!.id);
      currentSpinner!.items.add(newItem);
      spinners[index] = currentSpinner!;
    });
    _saveSpinners();
  }

  void _editItem(SpinnerItem item) {
    final titleController = TextEditingController(text: item.title);
    final descriptionController = TextEditingController(text: item.description);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  final index = currentSpinner!.items.indexWhere((i) => i.id == item.id);
                  currentSpinner!.items[index] = SpinnerItem(
                    id: item.id,
                    title: titleController.text,
                    description: descriptionController.text,
                  );
                });
                _saveSpinners();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(String id) {
    if (currentSpinner!.items.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete: Minimum 2 items required'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      currentSpinner!.items.removeWhere((item) => item.id == id);
    });
    _saveSpinners();
  }

  void _showAddItemDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                _addItem(titleController.text, descriptionController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showItemDetails(SpinnerItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Text(item.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildRightDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.settings, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Edit ${currentSpinner!.name}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Items'),
                      Tab(text: 'Style'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildItemsList(),
                        _buildStylesList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _showAddItemDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: currentSpinner!.items.length,
            itemBuilder: (context, index) {
              final item = currentSpinner!.items[index];
              return ListTile(
                title: Text(item.title),
                subtitle: Text(
                  item.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editItem(item),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: currentSpinner!.items.length <= 2
                          ? null
                          : () => _deleteItem(item.id),
                      color: currentSpinner!.items.length <= 2 ? Colors.grey : Colors.red,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStylesList() {
    return ListView.builder(
      itemCount: predefinedStyles.length,
      itemBuilder: (context, index) {
        final style = predefinedStyles[index];
        return ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: style.backgroundColor,
              border: Border.all(
                color: style.borderColor,
                width: style.borderWidth,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'Ab',
                style: TextStyle(
                  color: style.textColor,
                  fontSize: style.fontSize,
                  fontWeight: style.fontWeight,
                ),
              ),
            ),
          ),
          title: Text(style.name),
          trailing: Radio<String>(
            value: style.id,
            groupValue: currentSpinner!.style.id,
            onChanged: (value) {
              setState(() {
                final index = spinners.indexWhere((s) => s.id == currentSpinner!.id);
                final updatedSpinner = Spinner(
                  id: currentSpinner!.id,
                  name: currentSpinner!.name,
                  items: currentSpinner!.items,
                  style: style,
                );
                spinners[index] = updatedSpinner;
                currentSpinner = updatedSpinner;
                _saveSpinners();
              });
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentSpinner == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Text(currentSpinner!.name),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 48),
              color: Theme.of(context).colorScheme.primaryContainer,
              width: double.infinity,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.casino, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'My Spinners',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _addSpinner,
                icon: const Icon(Icons.add),
                label: const Text('Create New Spinner'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: spinners.length,
                itemBuilder: (context, index) {
                  final spinner = spinners[index];
                  return ListTile(
                    selected: currentSpinner!.id == spinner.id,
                    leading: const Icon(Icons.casino),
                    title: Text(spinner.name),
                    subtitle: Text(
                      '${spinner.items.length} items',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editSpinner(spinner),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: spinners.length <= 1
                              ? null
                              : () => _deleteSpinner(spinner.id),
                          color: spinners.length <= 1 ? Colors.grey : Colors.red,
                        ),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        currentSpinner = spinner;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      endDrawer: _buildRightDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: currentSpinner!.items.length < 2
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Add at least 2 items to start spinning!',
                            style: TextStyle(fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _showAddItemDialog,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FortuneWheel(
                        selected: _selected.stream,
                        animateFirst: false,
                        onAnimationEnd: () {
                          setState(() {
                            isSpinning = false;
                          });
                          int selectedIndex = currentSpinner!.items.length - 1;
                          _selected.stream.listen((value) {
                            selectedIndex = value;
                          });
                          _showItemDetails(currentSpinner!.items[selectedIndex]);
                        },
                        items: currentSpinner!.items
                            .map((item) => FortuneItem(
                                  style: FortuneItemStyle(
                                    color: currentSpinner!.style.backgroundColor,
                                    borderColor: currentSpinner!.style.borderColor,
                                    borderWidth: currentSpinner!.style.borderWidth,
                                    textStyle: TextStyle(
                                      fontSize: currentSpinner!.style.fontSize,
                                      fontWeight: currentSpinner!.style.fontWeight,
                                      color: currentSpinner!.style.textColor,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: currentSpinner!.style.fontSize,
                                        fontWeight: currentSpinner!.style.fontWeight,
                                        color: currentSpinner!.style.textColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: currentSpinner!.items.length < 2 || isSpinning
                    ? null
                    : () {
                        setState(() {
                          isSpinning = true;
                        });
                        _selected.add(Fortune.randomInt(0, currentSpinner!.items.length));
                      },
                child: const Text(
                  'SPIN!',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
