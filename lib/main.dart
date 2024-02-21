import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '/screens/certification.dart';
import '/screens/certification_result.dart';
import '/screens/certification_test.dart';
import '/screens/home.dart';
import '/screens/payment.dart';
import '/screens/payment_result.dart';
import '/screens/payment_test.dart';
import 'main2.dart';

void main() {
  runApp(IamportApp());
}

class IamportApp extends StatefulWidget {
  @override
  _IamportAppState createState() => _IamportAppState();
}

class _IamportAppState extends State<IamportApp> {
  static const Color primaryColor = Color(0xff344e81);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ));
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return GetMaterialApp(
      initialRoute: '/',
      theme: ThemeData(
        primaryColor: primaryColor,
      ),
      getPages: [
        GetPage(name: '/', page: () => const InAppWebViewScreen()),
        GetPage(name: '/payment-test', page: () => PaymentTest()),
        GetPage(name: '/payment', page: () => Payment()),
        GetPage(name: '/payment-result', page: () => PaymentResult()),
        GetPage(name: '/certification-test', page: () => CertificationTest()),
        GetPage(name: '/certification', page: () => Certification()),
        GetPage(
            name: '/certification-result', page: () => CertificationResult()),
      ],
    );
  }
}
