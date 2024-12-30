import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:uuid/uuid.dart';
import 'package:confetti/confetti.dart';
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
      title: 'Spinner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
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
  int? selectedIndex;
  StreamSubscription<int>? _subscription;
  late ConfettiController _confettiController;

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

  int _getWeightedRandomIndex(List<SpinnerItem> items) {
    final random = Random();
    final totalWeight = items.fold(0.0, (sum, item) => sum + item.weight);
    double randomWeight = random.nextDouble() * totalWeight;
    
    for (int i = 0; i < items.length; i++) {
      randomWeight -= items[i].weight;
      if (randomWeight <= 0) {
        return i;
      }
    }
    return items.length - 1;
  }

  void _createSpinner(String name) {
    final newSpinner = Spinner(
      id: _uuid.v4(),
      name: name,
      items: [
        SpinnerItem(
          id: _uuid.v4(),
          title: 'Item 1',
          description: 'First item',
          enabled: true,
          weight: 1.0,
        ),
        SpinnerItem(
          id: _uuid.v4(),
          title: 'Item 2',
          description: 'Second item',
          enabled: true,
          weight: 1.0,
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
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadSpinners();
  }

  @override
  void dispose() {
    _selected.close();
    _subscription?.cancel();
    _confettiController.dispose();
    super.dispose();
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
                  enabled: true,
                  weight: 1.0,
                ),
                SpinnerItem(
                  id: _uuid.v4(),
                  title: 'Item 2',
                  description: 'Second item',
                  enabled: true,
                  weight: 1.0,
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
        enabled: true,
        weight: 1.0,
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
    final weightController = TextEditingController(text: (item.weight * 100).toStringAsFixed(2));
    bool isEnabled = item.enabled;
    double? weight = item.weight;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
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
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(
                  labelText: 'Weight (%)',
                  hintText: 'Enter value between 0.01 and 99.99',
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  if (value.isEmpty) {
                    setState(() => weight = 1.0);
                    return;
                  }
                  final parsed = double.tryParse(value);
                  if (parsed != null && parsed >= 0.01 && parsed <= 99.99) {
                    setState(() => weight = parsed / 100);
                  }
                },
              ),
              CheckboxListTile(
                title: const Text('Enabled'),
                value: isEnabled,
                onChanged: (value) {
                  setState(() => isEnabled = value ?? true);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && weight != null) {
                setState(() {
                  final index = currentSpinner!.items.indexWhere((i) => i.id == item.id);
                  currentSpinner!.items[index] = SpinnerItem(
                    id: item.id,
                    title: titleController.text,
                    description: descriptionController.text,
                    enabled: isEnabled,
                    weight: weight!,
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
    // Get the enabled items list and selected item
    final enabledItems = currentSpinner!.items.where((item) => item.enabled).toList();
    SpinnerItem? selectedItem;
    
    if (selectedIndex != null) {
      final actualIndex = selectedIndex! % enabledItems.length;
      if (actualIndex >= 0 && actualIndex < enabledItems.length) {
        selectedItem = enabledItems[actualIndex];
        
        if (currentSpinner!.dynamicWeightScaling) {
          _updateWeightsAfterSpin(selectedItem);
        }
      }
    }

    // Use the selected item for the dialog if we found it, otherwise use the passed item
    final itemToShow = selectedItem ?? item;
    
    _confettiController.play();
    showDialog(
      context: context,
      builder: (context) => Stack(
        children: [
          Positioned(
            left: MediaQuery.of(context).size.width / 2,
            top: MediaQuery.of(context).size.height / 2,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              maxBlastForce: 25,
              minBlastForce: 10,
              gravity: 0.1,
              colors: currentSpinner!.style.colors,
              createParticlePath: (size) {
                var path = Path();
                path.addRect(
                  Rect.fromCircle(
                    center: Offset.zero,
                    radius: 5,
                  ),
                );
                return path;
              },
            ),
          ),
          AlertDialog(
            title: Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    currentSpinner!.style.colors[0],
                    currentSpinner!.style.colors[currentSpinner!.style.colors.length ~/ 2],
                  ],
                ).createShader(bounds),
                child: Text(
                  itemToShow.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  itemToShow.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
        ],
      ),
    );
  }

  void _spin() {
    if (!isSpinning && currentSpinner!.items.length >= 2) {
      setState(() {
        isSpinning = true;
        selectedIndex = null;
      });
      
      _subscription?.cancel();
      _subscription = _selected.stream.listen((value) {
        setState(() {
          selectedIndex = value;
        });
      });
      
      // Get weighted random index
      final selectedIdx = _getWeightedRandomIndex(currentSpinner!.items.where((item) => item.enabled).toList());
      
      // Find the number of full rotations we want (between 3 and 5)
      final fullRotations = Random().nextInt(3) + 3;
      
      // Calculate the final value for Fortune.randomInt
      final fortuneValue = (fullRotations * currentSpinner!.items.where((item) => item.enabled).length) + selectedIdx;
      
      _selected.add(fortuneValue);
    }
  }

  void _updateWeightsAfterSpin(SpinnerItem selectedItem) {
    if (!currentSpinner!.dynamicWeightScaling) return;

    final enabledItems = currentSpinner!.items.where((item) => item.enabled).toList();
    if (enabledItems.length <= 1) return;

    // Convert penalty percentage to multiplier
    final multiplier = 1.0 - (currentSpinner!.selectedPenalty / 100.0);
    
    // Calculate weight changes
    final oldWeight = selectedItem.weight;
    final newWeight = oldWeight * multiplier;
    final weightToRedistribute = oldWeight - newWeight;
    final distribution = weightToRedistribute / (enabledItems.where((item) => item.id != selectedItem.id).length);

    print('\n=== Weight Redistribution Details ===');
    print('Spinner: ${currentSpinner!.name}');
    print('Selected Item: ${selectedItem.title} (ID: ${selectedItem.id})');
    print('Current Weight: ${(oldWeight * 100).toStringAsFixed(1)}%');
    print('Penalty Multiplier: ${(multiplier * 100).toStringAsFixed(1)}%');
    print('New Weight: ${(newWeight * 100).toStringAsFixed(1)}%');
    print('Weight to Redistribute: ${(weightToRedistribute * 100).toStringAsFixed(1)}%');
    print('Distribution per Item: ${(distribution * 100).toStringAsFixed(1)}%');
    print('\nEnabled Items (${enabledItems.length}):');
    enabledItems.forEach((item) {
      print('${item.title} (ID: ${item.id}): ${(item.weight * 100).toStringAsFixed(1)}%');
    });

    final updatedItems = currentSpinner!.items.map((item) {
      if (!item.enabled) return item;

      double adjustedWeight;
      if (item.id == selectedItem.id) {
        adjustedWeight = newWeight;
        print('\nUpdating selected item ${item.title}:');
        print('Old weight: ${(item.weight * 100).toStringAsFixed(1)}%');
        print('New weight: ${(adjustedWeight * 100).toStringAsFixed(1)}%');
      } else {
        adjustedWeight = min(currentSpinner!.maxWeight / 100.0, item.weight + distribution);
        print('\nUpdating other item ${item.title}:');
        print('Old weight: ${(item.weight * 100).toStringAsFixed(1)}%');
        print('New weight: ${(adjustedWeight * 100).toStringAsFixed(1)}%');
      }

      return SpinnerItem(
        id: item.id,
        title: item.title,
        description: item.description,
        enabled: item.enabled,
        weight: max(0.0001, adjustedWeight),
      );
    }).toList();

    print('\nFinal Weights:');
    updatedItems.where((item) => item.enabled).forEach((item) {
      print('${item.title}: ${(item.weight * 100).toStringAsFixed(1)}%');
    });
    print('===============================\n');

    setState(() {
      final index = spinners.indexWhere((s) => s.id == currentSpinner!.id);
      final updatedSpinner = currentSpinner!.copyWith(items: updatedItems);
      spinners[index] = updatedSpinner;
      currentSpinner = updatedSpinner;
      _saveSpinners();
    });
  }

  Widget _buildRightDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: currentSpinner?.style.colors ?? [Colors.blue, Colors.lightBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                currentSpinner?.name ?? 'Spinner',
                style: TextStyle(
                  color: currentSpinner?.style.textColor ?? Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  TabBar(
                    tabs: const [
                      Tab(text: 'Items'),
                      Tab(text: 'Style'),
                      Tab(text: 'Settings'),
                    ],
                    labelColor: Theme.of(context).colorScheme.primary,
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildItemsList(),
                        _buildStylesList(),
                        _buildSettingsList(),
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

  Widget _buildSettingsList() {
    return ListView(
      children: [
        SwitchListTile(
          title: const Text('Show Percentages'),
          subtitle: const Text('Display probability percentages on the wheel'),
          value: currentSpinner!.showPercentages,
          onChanged: (value) {
            setState(() {
              final index = spinners.indexWhere((s) => s.id == currentSpinner!.id);
              final updatedSpinner = currentSpinner!.copyWith(showPercentages: value);
              spinners[index] = updatedSpinner;
              currentSpinner = updatedSpinner;
              _saveSpinners();
            });
          },
        ),
        const Divider(),
        SwitchListTile(
          title: const Text('Dynamic Weight Scaling'),
          subtitle: const Text('Automatically adjust weights after each spin'),
          value: currentSpinner!.dynamicWeightScaling,
          onChanged: (value) {
            setState(() {
              final index = spinners.indexWhere((s) => s.id == currentSpinner!.id);
              final updatedSpinner = currentSpinner!.copyWith(dynamicWeightScaling: value);
              spinners[index] = updatedSpinner;
              currentSpinner = updatedSpinner;
              _saveSpinners();
            });
          },
        ),
        if (currentSpinner!.dynamicWeightScaling)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Item Penalty',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: currentSpinner!.selectedPenalty,
                        min: 1,
                        max: 100,
                        divisions: 99,
                        label: '${currentSpinner!.selectedPenalty.round()}%',
                        onChanged: (value) {
                          setState(() {
                            final index = spinners.indexWhere((s) => s.id == currentSpinner!.id);
                            final updatedSpinner = currentSpinner!.copyWith(selectedPenalty: value);
                            spinners[index] = updatedSpinner;
                            currentSpinner = updatedSpinner;
                            _saveSpinners();
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        '${currentSpinner!.selectedPenalty.round()}%',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Percentage to reduce selected item\'s weight by (multiplicative)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                final index = spinners.indexWhere((s) => s.id == currentSpinner!.id);
                final updatedItems = currentSpinner!.items.map((item) => 
                  SpinnerItem(
                    id: item.id,
                    title: item.title,
                    description: item.description,
                    enabled: item.enabled,
                    weight: 1.0, // Store as decimal (1.0 = 100%)
                  )
                ).toList();
                final updatedSpinner = currentSpinner!.copyWith(items: updatedItems);
                spinners[index] = updatedSpinner;
                currentSpinner = updatedSpinner;
                _saveSpinners();
              });
            },
            icon: const Icon(Icons.restore),
            label: const Text('Reset All Weights'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
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
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: item.enabled,
                      onChanged: (value) {
                        setState(() {
                          final index = currentSpinner!.items.indexWhere((i) => i.id == item.id);
                          currentSpinner!.items[index] = SpinnerItem(
                            id: item.id,
                            title: item.title,
                            description: item.description,
                            enabled: value ?? true,
                            weight: item.weight,
                          );
                        });
                        _saveSpinners();
                      },
                    ),
                    Expanded(
                      child: ListTile(
                        title: Text(
                          item.title,
                          style: TextStyle(
                            color: item.enabled ? null : Theme.of(context).disabledColor,
                          ),
                        ),
                        subtitle: Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.enabled ? null : Theme.of(context).disabledColor,
                          ),
                        ),
                      ),
                    ),
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

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentSpinner == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final enabledItems = currentSpinner!.items.where((item) => item.enabled).toList();
    final hasEnoughEnabledItems = enabledItems.length >= 2;

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
              child: hasEnoughEnabledItems
                  ? Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = min(
                            min(constraints.maxWidth * 0.9, constraints.maxHeight * 0.9),
                            500.0,
                          );
                          return SizedBox(
                            width: size,
                            height: size,
                            child: Stack(
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
                                    onFling: hasEnoughEnabledItems ? _spin : null,
                                    onAnimationEnd: () {
                                      setState(() {
                                        isSpinning = false;
                                      });
                                      if (selectedIndex != null) {
                                        final actualIndex = selectedIndex! % enabledItems.length;
                                        _showItemDetails(enabledItems[actualIndex]);
                                      }
                                    },
                                    styleStrategy: UniformStyleStrategy(
                                      borderWidth: 0,
                                      borderColor: Colors.transparent,
                                    ),
                                    indicators: [
                                      FortuneIndicator(
                                        alignment: const Alignment(0, -1.04),
                                        child: SizedBox(
                                          width: 20,
                                          height: 30,
                                          child: CustomPaint(
                                            painter: TrianglePainter(
                                              color: Colors.black,
                                              gradientColors: [
                                                currentSpinner!.style.colors[0],
                                                currentSpinner!.style.colors[currentSpinner!.style.colors.length ~/ 2],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    items: enabledItems
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
                                              padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    style: TextStyle(
                                                      fontSize: currentSpinner!.style.fontSize,
                                                      fontWeight: currentSpinner!.style.fontWeight,
                                                      color: currentSpinner!.style.textColor,
                                                    ),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  if (currentSpinner!.showPercentages)
                                                    Text(
                                                      '${(item.weight * 100).toStringAsFixed(1)}%',
                                                      style: TextStyle(
                                                        fontSize: currentSpinner!.style.fontSize * 0.8,
                                                        color: currentSpinner!.style.textColor,
                                                      ),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        currentSpinner!.style.colors[0],
                                        currentSpinner!.style.colors[currentSpinner!.style.colors.length ~/ 2],
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
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
                                      onTap: isSpinning ? null : _spin,
                                      customBorder: const CircleBorder(),
                                      child: Center(
                                        child: Icon(
                                          Icons.play_arrow,
                                          size: 30,
                                          color: isSpinning
                                            ? currentSpinner!.style.textColor.withOpacity(0.5)
                                            : currentSpinner!.style.textColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.warning, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Add at least 2 enabled items to spin!',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final List<Color> gradientColors;

  TrianglePainter({
    required this.color,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(size.width / 2, size.height / 0.9);
    path.lineTo(0, 0);                         // Line to top-left
    path.lineTo(size.width, 0);                // Line to top-right
    path.close();

    // Fill with solid color
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw gradient outline
    final outlinePaint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, outlinePaint);
  }

  @override
  bool shouldRepaint(TrianglePainter oldDelegate) =>
    color != oldDelegate.color ||
    !listEquals(gradientColors, oldDelegate.gradientColors);
}
