import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// void main() => runApp(const MyApp());

class PeriodCard extends StatelessWidget {
  final String phase; // The current phase of the cycle
  final String startDate; // The start date of the current period
  final String endDate; // The end date of the current period
  final int daysLeft; // The number of days left until the next period
  final int stepsToday; // The number of steps taken today

  const PeriodCard({
    super.key,
    required this.phase,
    required this.startDate,
    required this.endDate,
    required this.daysLeft,
    required this.stepsToday,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: SizedBox(
          height: 120,
          width: 380,
          child: Container(
            decoration: BoxDecoration(
              // image: const DecorationImage(
              //   image: NetworkImage(
              //       'https://media.geeksforgeeks.org/wp-content/cdn-uploads/logo.png'),
              //   scale: 3.0,
              // ),
              border: Border.all(
                  color: const Color.fromARGB(255, 38, 38, 38),
                  width: 2.0,
                  style: BorderStyle.solid),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(25.0),
                topRight: Radius.circular(25.0),
                bottomLeft: Radius.circular(25.0),
                bottomRight: Radius.circular(25.0),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(255, 189, 189, 189),
                  offset: Offset(
                    5.0,
                    5.0,
                  ),
                  blurRadius: 5.0,
                  spreadRadius: 1.0,
                ), //BoxShadow
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(0.0, 0.0),
                  blurRadius: 0.0,
                  spreadRadius: 0.0,
                ), //BoxShadow
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                // mainAxisAlignment: ,
                children: [
                  Text(
                    phase,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  // Text('Current cycle: $startDate - $endDate'),
                  Text('$daysLeft days until next period'),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Text('Steps today: $stepsToday'),
                      const Spacer(),
                      const Text('Goal: 10,000 steps'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Home extends StatelessWidget {
  int data;

  Home({required this.data});

  List<String> days = [
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12',
    '13',
    '14',
    '15',
    '16',
    '17',
    '18',
    '19',
    '20',
    '21',
    '22',
    '23',
    '24',
    '25',
    '26',
    '27',
    '28',
    '29',
    '30',
    '31'
  ];

  var One = const {
    "phase": "Test01",
    "startDate": "12/02/03",
    "endDate": "12/03/23",
    "daysLeft": 5,
    "stepsToday": 10,
  };

  var Two = const {
    "phase": "Test02",
    "startDate": "12/02/03",
    "endDate": "12/03/23",
    "daysLeft": 5,
    "stepsToday": 10,
  };
  var Three = const {
    "phase": "Test03",
    "startDate": "12/02/03",
    "endDate": "12/03/23",
    "daysLeft": 5,
    "stepsToday": 10,
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(children: [
          Container(
            // margin: const EdgeInsets.symmetric(vertical: 20),
            color: const Color(0xFF3A276A),
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                for (var index in days)
                  Container(
                    width: 50,
                    alignment: Alignment.center,
                    child: Text(
                      index,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                alignment: Alignment.center,
                child: const Text(
                  'Current Date',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
              Container(
                margin:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                alignment: Alignment.center,
                child: const Text(
                  'Period Duration',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          const Center(
              child: Column(
            children: <Widget>[
              PeriodCard(
                phase: "Test01",
                startDate: "12/02/03",
                endDate: "12/03/23",
                daysLeft: 5,
                stepsToday: 10,
              ),
              PeriodCard(
                phase: "Test02",
                startDate: "12/02/03",
                endDate: "12/03/23",
                daysLeft: 5,
                stepsToday: 10,
              ),
              PeriodCard(
                phase: "Test03",
                startDate: "12/02/03",
                endDate: "12/03/23",
                daysLeft: 5,
                stepsToday: 10,
              ),
            ],
          )),
          // Provider.of<DataModel>(context, listen: false).updateData('Data from Home');
          // return Center(

          // );
        ]),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
