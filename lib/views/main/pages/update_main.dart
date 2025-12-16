import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Missing_Persons_Platform/views/main/pages/profile_main.dart';
import 'package:lottie/lottie.dart';

import '../../../main.dart';

class UpdateMain extends StatefulWidget {
  const UpdateMain({super.key});

  @override
  State<UpdateMain> createState() => _UpdateMainState();
}

class _UpdateMainState extends State<UpdateMain> {
  Query dbRef = FirebaseDatabase.instance.ref().child('Reports');
  List<Map> reportList = [];
  List<Map> reportListCopy = [];
  List<Map> reportListOriginal = [];
  TextEditingController editingController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  bool firstCheck = true;

  void filterSearchResults(String query) {
    setState(() {
      reportList = reportListCopy.where((item) {
        if (item.containsKey('status')) {
          var firstName = item['p3_mp_firstName'] ?? '';
          var lastName = item['p3_mp_lastName'] ?? '';
          var combinedName =
              firstName + lastName == '' ? 'لا يوجد اسم' : firstName + lastName;
          var status = item['status'] ?? '';
          var searchToken = combinedName + status;
          var returnVal =
              searchToken.toLowerCase().contains(query.toLowerCase());
          return returnVal;
        } else {
          return false;
        }
      }).toList();
      print('reportCopy len: ${reportListCopy.length}');
      print('report len: ${reportList.length}');
    });
    reportListCopy = List.from(reportList);
  }

  Widget listItem({required Map report}) {
    String reportName = 'لا يوجد اسم';
    if (report['p3_mp_lastName'] != null && report['p3_mp_firstName'] != null) {
      reportName = report['p3_mp_firstName'] + " " + report['p3_mp_lastName'];
    }

    String status = report['status'];

    Color containerColor;
    switch (status) {
      case 'Pending':
        containerColor = Palette.indigo;
        break;
      case 'Verified':
        containerColor = Colors.green;
        break;
      case 'Rejected':
        containerColor = Colors.deepOrange;
        break;
      case 'Already Found':
        containerColor = Colors.yellow;
        break;
      default:
        containerColor = Colors.grey;
        break;
    }

    Text statusChange;
    switch (status) {
      case 'Pending':
        statusChange = const Text('مستلم',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center);
        break;
      case 'verified':
        statusChange = const Text('تم التحقق',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center);
        break;
      case 'Rejected':
        statusChange = const Text('مرفوض',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center);
        break;
      case 'Already Found':
        statusChange = const Text('تم العثور',
            style: TextStyle(color: Colors.black), textAlign: TextAlign.center);
        break;
      default:
        statusChange = const Text('غير مكتمل',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center);
        break;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 3,
      child: ListTile(
        title: Text(
          reportName,
          style: GoogleFonts.tajawal(
              textStyle: TextStyle(fontWeight: FontWeight.w700)),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Visibility(
              visible: report['status'] != 'Already Found',
              child: Text(
                "تاريخ الإبلاغ: ${report['p5_reportDate']}",
                textScaleFactor: 0.75,
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
            Visibility(
              visible: report['status'] == 'Already Found',
              child: Text(
                "تاريخ العثور: ${report['p5_reportDate']}",
                textScaleFactor: 0.75,
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
            ),
            if (report['status'] == 'Rejected')
              TextButton(
                onPressed: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0))),
                            title: const Text('سبب الرفض',
                                style: TextStyle(fontFamily: 'Tajawal')),
                            content: Text(report['pnp_rejectReason'] ??
                                'لا يوجد سبب محدد للرفض',
                                style: TextStyle(fontFamily: 'Tajawal')));
                      });
                },
                child: Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'عرض الملاحظات',
                      textScaleFactor: 0.8,
                      style: TextStyle(fontFamily: 'Tajawal'),
                    )),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: MediaQuery.of(context).size.width * 0.25,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: containerColor),
              child: statusChange,
            ),
          ],
        ),
      ),
    );
  }

  StreamSubscription? _subscription;
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  static const TextStyle optionStyle = TextStyle(
      fontSize: 24, 
      fontWeight: FontWeight.bold, 
      color: Colors.black54,
      fontFamily: 'Tajawal');

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header Section
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: EdgeInsets.only(top: MediaQuery.of(context).size.height / 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: Image.asset('assets/images/Missing_Persons_PlatformLogo.png', width: 35),
              ),
              Text(
                'التحديثات',
                style: TextStyle(
                  fontSize: 20.0, 
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Tajawal'
                ),
                textAlign: TextAlign.center,
              ),
              IconButton(
                icon: Icon(Icons.account_circle_outlined, size: 30),
                selectedIcon: Icon(Icons.account_circle, size: 30),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileMain(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Reports Title Section
        Container(
          margin: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * .05, 
            bottom: 20
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(
                  left: MediaQuery.of(context).size.width * 0.1
                ),
                child: Text(
                  'التقارير',
                  style: GoogleFonts.tajawal(
                    textStyle: TextStyle(
                      fontWeight: FontWeight.w900, 
                      fontSize: 26,
                      color: Colors.black87
                    )
                  ),
                ),
              ),
            ],
          ),
        ),

        // Reports List Section
        Container(
          height: MediaQuery.of(context).size.height * .65,
          width: MediaQuery.of(context).size.width * .85,
          child: StreamBuilder(
            stream: dbRef.onValue,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              print('snapshot: $snapshot');
              if (!snapshot.hasData) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SpinKitCubeGrid(
                        color: Palette.indigo,
                        size: 30.0,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'جاري التحميل...',
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 16,
                          color: Colors.black54
                        ),
                      )
                    ],
                  ),
                );
              }
              reportList.clear();
              dynamic values = snapshot.data?.snapshot.value;
              if (values != null) {
                Map<dynamic, dynamic> reports = values;
                reports.forEach((key, value) {
                  dynamic uid = key;
                  if (key == user?.uid) {
                    value.forEach((key, value) {
                      value['key'] = '${key}__$uid';
                      value['uid'] = uid;
                      reportList.add(value);
                    });
                  }
                });
                if (reportList.isEmpty) {
                  return Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height * .05
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'لا توجد تقارير بعد',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            fontFamily: 'Tajawal'
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'قم بالإبلاغ عن شخص مفقود',
                          textScaleFactor: 0.9,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.black54
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 30),
                          child: Lottie.asset(
                            "assets/lottie/noReports.json",
                            animate: true,
                            width: MediaQuery.of(context).size.width * 0.8
                          ),
                        ),
                      ],
                    ),
                  );
                }
              } else {
                return Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'لا توجد تقارير بعد',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'Tajawal'
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'قم بالإبلاغ عن شخص مفقود',
                        textScaleFactor: 0.9,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          color: Colors.black54
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                          top: 30,
                          bottom: MediaQuery.of(context).size.height * 0.30
                        ),
                        child: Lottie.network(
                          "https://assets3.lottiefiles.com/private_files/lf30_lKuCPz.json",
                          animate: true,
                          width: MediaQuery.of(context).size.width * 0.8
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                itemCount: reportList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: listItem(report: reportList[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}