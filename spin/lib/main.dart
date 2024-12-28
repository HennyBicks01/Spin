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
      id: 'rainbow',
      name: 'Rainbow',
      colors: [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.indigo,
        Colors.purple,
      ],
      textColor: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    SpinnerStyle(
      id: 'ocean',
      name: 'Ocean',
      colors: [
        const Color(0xFF1A237E), // Deep blue
        const Color(0xFF0D47A1), // Navy
        const Color(0xFF0288D1), // Ocean blue
        const Color(0xFF26C6DA), // Turquoise
        const Color(0xFF80DEEA), // Light blue
      ],
      textColor: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    SpinnerStyle(
      id: 'sunset',
      name: 'Sunset',
      colors: [
        const Color(0xFFFF1744), // Bright red
        const Color(0xFFFF4081), // Pink
        const Color(0xFFFF9100), // Orange
        const Color(0xFFFFD740), // Yellow
      ],
      textColor: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    SpinnerStyle(
      id: 'forest',
      name: 'Forest',
      colors: [
        const Color(0xFF1B5E20), // Dark green
        const Color(0xFF2E7D32), // Forest green
        const Color(0xFF388E3C), // Medium green
        const Color(0xFF43A047), // Light green
        const Color(0xFF66BB6A), // Pale green
      ],
      textColor: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    SpinnerStyle(
      id: 'candy',
      name: 'Candy',
      colors: [
        const Color(0xFFEC407A), // Pink
        const Color(0xFFAB47BC), // Purple
        const Color(0xFF7E57C2), // Violet
        const Color(0xFF42A5F5), // Blue
        const Color(0xFF26C6DA), // Cyan
      ],
      textColor: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ];

  void _createSpinner(String name) {
    final newSpinner = Spinner(
      id: _uuid.v4(),
      name: name,
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
      style: SpinnerStyle(
        id: 'rainbow',
        name: 'Rainbow',
        colors: [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.indigo,
          Colors.purple,
        ],
        textColor: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
    setState(() {
      spinners.add(newSpinner);
      currentSpinner = newSpinner;
    });
    _saveSpinners();
  }

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
        _createSpinner('Coin Flip');
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
      _createSpinner('Default Spinner');
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
                _createSpinner(nameController.text);
                Navigator.pop(context);
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
              gradient: LinearGradient(
                colors: style.colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
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

  void _spin() {
    if (!isSpinning && currentSpinner!.items.length >= 2) {
      setState(() {
        isSpinning = true;
      });
      _selected.add(Fortune.randomInt(0, currentSpinner!.items.length));
    }
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
                          const Icon(Icons.warning, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Add at least 2 items to spin!',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        GestureDetector(
                          onTap: _spin,
                          child: FortuneWheel(
                            selected: _selected.stream,
                            animateFirst: false,
                            physics: CircularPanPhysics(
                              duration: const Duration(seconds: 1),
                              curve: Curves.decelerate,
                            ),
                            onFling: _spin,
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
                            styleStrategy: UniformStyleStrategy(
                              borderWidth: 0,
                              borderColor: Colors.transparent,
                            ),
                            items: currentSpinner!.items
                                .asMap()
                                .entries
                                .map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
                                  final colorIndex = index % currentSpinner!.style.colors.length;
                                  return FortuneItem(
                                    style: FortuneItemStyle(
                                      color: currentSpinner!.style.colors[colorIndex],
                                      borderWidth: 0,
                                      borderColor: Colors.transparent,
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
                                  );
                                })
                                .toList(),
                          ),
                        ),
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _spin,
                              customBorder: const CircleBorder(),
                              child: Center(
                                child: Icon(
                                  isSpinning ? Icons.refresh : Icons.play_arrow,
                                  size: 40,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
