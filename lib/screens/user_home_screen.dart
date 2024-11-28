import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key, required this.email});

  final String email;

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  String username = '';
  List<Map<String, dynamic>> hostels = [];

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadHostels();
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? users = prefs.getStringList('users');
    if (users != null) {
      for (var user in users) {
        var details = user.split(',');
        if (details[1] == widget.email) {
          setState(() {
            username = details[0];
          });
          break;
        }
      }
    }
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
        };
      }).toList();
    });
  }

  Future<void> _bookHostel(String hostelDetails) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? hostelStrings = prefs.getStringList('hostels') ?? [];
    for (int i = 0; i < hostelStrings.length; i++) {
      if (hostelStrings[i].startsWith(hostelDetails) && hostelStrings[i].endsWith('available')) {
        var details = hostelStrings[i].split(',');
        hostelStrings[i] = '${details[0]},${details[1]},${details[2]},pending';
        break;
      }
    }
    await prefs.setStringList('hostels', hostelStrings);
    _sendNotificationToAdmin(hostelDetails);
    _loadHostels(); // Refresh the list after booking
    _showBookingAlert(); // Show alert after booking
  }

  Future<void> _sendNotificationToAdmin(String hostelDetails) async {
    // Simulate sending a notification to the admin
    // In a real app, this would involve using a backend service or messaging system
    print('Notification to Admin: A new booking request for $hostelDetails');
  }

  void _showBookingAlert() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Booking Request Sent'),
          content: const Text('Your booking request has been sent. The admin will review and respond to your request soon.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username.isNotEmpty ? username : 'User'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: hostels.length,
              itemBuilder: (context, index) {
                final hostel = hostels[index];
                if (hostel['status'] == 'available') {
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(hostel['blockName']!),
                      subtitle: Text('${hostel['roomType']} - \$${hostel['price']}'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _bookHostel('${hostel['blockName']},${hostel['roomType']},${hostel['price']}');
                        },
                        child: const Text('Book Now'),
                      ),
                    ),
                  );
                } else {
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(hostel['blockName']!),
                      subtitle: Text('${hostel['roomType']} - \$${hostel['price']} (Status: ${hostel['status']})'),
                    ),
                  );
                }
              },
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await _deleteCredentials();
                Navigator.pop(context);  // Go back to login screen after deleting credentials
              },
              child: const Text("Log Out"),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? userStrings = prefs.getStringList('users');
    if (userStrings != null) {
      userStrings.removeWhere((user) => user.contains(widget.email));
      await prefs.setStringList('users', userStrings);
    }
    await prefs.remove('email');
    await prefs.remove('password');
  }
}
