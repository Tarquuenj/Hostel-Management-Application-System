import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  List<Map<String, String>> users = [];
  List<Map<String, String>> hostels = [];
  List<Map<String, String>> requests = []; // New list for requests
  final _formKey = GlobalKey<FormState>();
  TextEditingController blockNameController = TextEditingController();
  TextEditingController roomTypeController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // Updated tab length to 3
    _loadUsers();
    _loadHostels();
    _loadRequests(); // Load requests
  }

  Future<void> _loadUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userStrings = prefs.getStringList('users') ?? [];
    setState(() {
      users = userStrings.map((user) {
        var details = user.split(',');
        return {
          'username': details[0],
          'email': details[1],
          'password': details[2],
        };
      }).toList();
    });
  }

  Future<void> _loadHostels() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    setState(() {
      hostels = hostelStrings.map((hostel) {
        var details = hostel.split(',');
        return {
          'blockName': details[0],
          'roomType': details[1],
          'price': details[2],
          'status': details.length > 3 ? details[3] : 'available',
          'occupants': details.length > 4 ? details[4] : '', // New field for occupants
        };
      }).toList();
    });
  }

  Future<void> _loadRequests() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? requestStrings = prefs.getStringList('requests') ?? [];
    setState(() {
      requests = requestStrings.map((request) {
        var details = request.split(',');
        return {
          'requester': details[0],
          'hostel': details[1],
          'status': details[2],
        };
      }).toList();
    });
  }

  Future<void> _updateRequestStatus(String requestDetails, String newStatus) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? requestStrings = prefs.getStringList('requests') ?? [];
    for (int i = 0; i < requestStrings.length; i++) {
      if (requestStrings[i].startsWith(requestDetails)) {
        var details = requestStrings[i].split(',');
        requestStrings[i] = '${details[0]},${details[1]},$newStatus';
        break;
      }
    }
    await prefs.setStringList('requests', requestStrings);
    _loadRequests(); // Refresh the list after updating
  }

  Future<void> _deleteRequest(String requestDetails) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? requestStrings = prefs.getStringList('requests') ?? [];
    requestStrings.removeWhere((request) => request.startsWith(requestDetails));
    await prefs.setStringList('requests', requestStrings);
    _loadRequests(); // Refresh the list after deleting
  }

  Future<void> _updateHostelStatus(String hostelDetails, String newStatus, [String occupant = '']) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    for (int i = 0; i < hostelStrings.length; i++) {
      if (hostelStrings[i].startsWith(hostelDetails)) {
        var details = hostelStrings[i].split(',');
        hostelStrings[i] = '${details[0]},${details[1]},${details[2]},$newStatus,$occupant';
        break;
      }
    }
    await prefs.setStringList('hostels', hostelStrings);
    _loadHostels(); // Refresh the list after updating
  }

  Future<void> _deleteHostel(String hostelDetails) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    hostelStrings.removeWhere((hostel) => hostel.startsWith(hostelDetails));
    await prefs.setStringList('hostels', hostelStrings);
    _loadHostels(); // Refresh the list after deleting
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Page'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Hostels'),
            Tab(text: 'Requests'), // New tab for requests
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Users Tab
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(user['username']!),
                        subtitle: Text(user['email']!),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Hostels Tab
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: hostels.length,
                  itemBuilder: (context, index) {
                    final hostel = hostels[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(hostel['blockName']!),
                        subtitle: Text('${hostel['roomType']} - \$${hostel['price']} (Status: ${hostel['status']})'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (String value) {
                            final hostelDetails = '${hostel['blockName']},${hostel['roomType']},${hostel['price']}';
                            if (value == 'Delete') {
                              _deleteHostel(hostelDetails);
                            } else if (value == 'Make Vacant') {
                              _updateHostelStatus(hostelDetails, 'available');
                            } else if (value == 'Accept') {
                              _updateHostelStatus(hostelDetails, 'occupied');
                            } else if (value == 'Reject') {
                              _updateHostelStatus(hostelDetails, 'rejected');
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              const PopupMenuItem<String>(
                                value: 'Delete',
                                child: Text('Delete'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Accept',
                                child: Text('Accept'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Reject',
                                child: Text('Reject'),
                              ),
                              if (hostel['status'] == 'occupied')
                                const PopupMenuItem<String>(
                                  value: 'Make Vacant',
                                  child: Text('Make Vacant'),
                                ),
                            ];
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: blockNameController,
                        decoration: const InputDecoration(labelText: 'Block Name'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a block name';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: roomTypeController,
                        decoration: const InputDecoration(labelText: 'Room Type'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a room type';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          return null;
                        },
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (_formKey.currentState?.validate() ?? false) {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
                            hostelStrings.add('${blockNameController.text},${roomTypeController.text},${priceController.text},available');
                            await prefs.setStringList('hostels', hostelStrings);
                            _loadHostels();
                            blockNameController.clear();
                            roomTypeController.clear();
                            priceController.clear();
                          }
                        },
                        child: const Text('Add Hostel'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Requests Tab
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Requester: ${request['requester']}'),
                        subtitle: Text('Hostel: ${request['hostel']} (Status: ${request['status']})'),
                        trailing: PopupMenuButton<String>(
                          onSelected: (String value) {
                            final requestDetails = '${request['requester']},${request['hostel']}';
                            if (value == 'Accept') {
                              _updateRequestStatus(requestDetails, 'accepted');
                            } else if (value == 'Reject') {
                              _updateRequestStatus(requestDetails, 'rejected');
                            }
                          },
                          itemBuilder: (BuildContext context) {
                            return [
                              const PopupMenuItem<String>(
                                value: 'Accept',
                                child: Text('Accept'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'Reject',
                                child: Text('Reject'),
                              ),
                            ];
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
