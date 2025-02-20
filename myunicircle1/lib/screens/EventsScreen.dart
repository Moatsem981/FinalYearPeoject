import 'package:flutter/material.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  _EventsScreenState createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final List<Map<String, dynamic>> events = [
    {
      "title": "Cultural Exchange Meetup",
      "date": "March 10, 2025",
      "time": "4:00 PM - 7:00 PM",
      "location": "Student Union Hall",
      "image": "assets/culture_event.jpg",
    },
    {
      "title": "Tech & AI Conference",
      "date": "March 15, 2025",
      "time": "10:00 AM - 5:00 PM",
      "location": "Tech Innovation Hub",
      "image": "assets/tech_event.jpg",
    },
    {
      "title": "Live Music Night",
      "date": "March 20, 2025",
      "time": "8:00 PM - 11:00 PM",
      "location": "Downtown Cafe",
      "image": "assets/music_event.jpg",
    },
    {
      "title": "Sports Tournament",
      "date": "March 25, 2025",
      "time": "12:00 PM - 6:00 PM",
      "location": "University Stadium",
      "image": "assets/sports_event.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F56BB),
        title: const Text("Upcoming Events"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return Card(
              color: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Event Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(10),
                    ),
                    child: Image.asset(
                      event["image"],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Event Title
                        Text(
                          event["title"],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 5),
                        // Date & Time
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              event["date"],
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              event["time"],
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        // Location
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              event["location"],
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Join Event Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              print("Joined ${event["title"]}");
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7F56BB),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              "Join Event",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
