import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:password_manager/password_manager.dart';
import 'package:password_manager/quizler.dart';
import 'package:password_manager/settings.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import 'home_page.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  List<Appointment> _appointments = <Appointment>[];
  Appointment _selectedAppointment;
  String mToken = " ";

  FirebaseMessaging messaging = FirebaseMessaging.instance;


  @override
  void initState() {
    super.initState();
    _appointments = getAppointments();
    requestPermission();
    getToken();
  }

  void requestPermission() async{
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized){
      print('User granted permission');
    }else if (settings.authorizationStatus == AuthorizationStatus.provisional){
      print('User granted provisional permission');
    }else{
      print('User declined or has not accepted permission');
    }
  }

  void getToken() async{
    await FirebaseMessaging.instance.getToken().then(
        (token){
          setState(() {
            mToken = token;
            print("My token is $mToken");
          });
          saveToken(token);
        }
    );
  }

  void saveToken(String token) async{
    await FirebaseFirestore.instance.collection("UserTokens").doc("User2").set({
      'token' : token,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar Book Events'),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Home()),
              );
            },
            child: Icon(Icons.home),
            backgroundColor: Color(0xff892cdc),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PasswordManager()),
              );
            },
            child: Icon(Icons.password),
            backgroundColor: Color(0xff892cdc),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => QuizPage()),
              );
            },
            child: Icon(Icons.quiz),
            backgroundColor: Color(0xff892cdc),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CalendarPage()),
              );
            },
            child: Icon(Icons.calendar_month),
            backgroundColor: Color(0xff892cdc),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
            child: Icon(Icons.settings),
            backgroundColor: Color(0xff892cdc),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      body: Container(
      height: MediaQuery.of(context).size.height / 2,
      child: SfCalendar(
        view: CalendarView.month,
        dataSource: MeetingDataSource(_appointments),

        onTap: (CalendarTapDetails details) async {
          final DateTime startTime = details.date;
          TimeOfDay time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay.now(),
          );
          if (time != null) {
            final DateTime selectedTime = DateTime(
                startTime.year, startTime.month, startTime.day, time.hour,
                time.minute);
            String selectedSubject = '';
            String selectedTitle = '';
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Book Appointment'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextField(
                        decoration: InputDecoration(hintText: 'Event Title'),
                        onChanged: (value){
                          selectedTitle = value;
                        },
                      ),
                      SizedBox(height: 10),
                      TextField(
                        decoration: InputDecoration(hintText: 'Subject'),
                        onChanged: (value){
                          selectedSubject = value;
                        },
                      ),
                    ],
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    FlatButton(
                      child: Text('Book'),
                      onPressed: () async {
                        setState(() {
                          _appointments.add(Appointment(
                            startTime: selectedTime,
                            endTime: selectedTime.add(Duration(hours: 1)),
                            subject: selectedSubject,
                            notes: selectedTitle,
                            color: Colors.blue,
                          ));
                        });
                        Navigator.of(context).pop();

                        // Schedule the notification to be sent in 1 minute
                        Timer(Duration(minutes: 1), () async {
                          // Send the notification using Firebase Cloud Messaging
                          await sendNotificationUsingFCM(selectedTitle, selectedSubject, mToken);
                        });
                      },
                    ),
                  ],
                );
              },
            );
          }
        },
       onLongPress: (CalendarLongPressDetails details){
          setState(() {
            final selectedAppointment = details.appointments.isNotEmpty
                ? details.appointments.first
                : null;
            if (selectedAppointment != null){
              showDialog(
                  context: context,
                  builder: (BuildContext context){
                    return AlertDialog(
                    title: Text('View Event'),
                    content: Text(
                      'Title: ${selectedAppointment.notes}\n' +
                      'Subject: ${selectedAppointment.subject}\n' +
                      'Start Time: ${selectedAppointment.startTime}\n' +
                      'End Time: ${selectedAppointment.endTime}'
                    ),
                    actions: <Widget>[
                      FlatButton(
                        onPressed: (){
                          Navigator.of(context).pop();

                        },
                        child: Text('OK'))
                    ],
                    );
                  }

                 );
            }
          });
       },
      ),
    )
    );
  }

  Future<void> sendNotificationUsingFCM(String title, String body, String fcmToken) async {
    String apiKey = "AIzaSyDX6IITSPq399OD7TD9M-rnN81CX_YNFkc";
    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$apiKey',
      },
      body: jsonEncode(<String, dynamic>{
        "notification": {
          "title": title,
          "body": body,
        },
        "priority": "high",
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "id": "1",
          "status": "done"
        },
        "to": fcmToken,
      }),
    );
    if (response.statusCode != 200) {
      print("Error sending notification: ${response.body}");
    }
  }


}

List<Appointment> getAppointments() {
  return [
    Appointment(
      startTime: DateTime.now().add(Duration(hours: 1)),
      endTime: DateTime.now().add(Duration(hours: 2)),
      subject: 'Its security awareness month',
      notes: 'Security Awareness',
      color: Colors.red,
    ),
    Appointment(
      startTime: DateTime.now().add(Duration(hours: 3)),
      endTime: DateTime.now().add(Duration(hours: 4)),
      subject: 'Learn how to build an antivirus',
      notes: 'Anti Virus Week',
      color: Colors.blue,
    ),
    Appointment(
      startTime: DateTime.now().add(Duration(hours: 5)),
      endTime: DateTime.now().add(Duration(hours: 6)),
      subject: 'Know how to protect your passwords the right way',
      notes: 'Password Protection 3.0',
      color: Colors.green,
    ),
  ];
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Appointment> source) {
    appointments = source;
  }
}








