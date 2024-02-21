import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:iamport_flutter/iamport_payment.dart';
import 'package:iamport_flutter/model/payment_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sangbang/screens/payment.dart';
import 'package:sangbang/screens/payment_test.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var status = await Permission.location.request();

  if (Platform.isAndroid) {
    await AndroidInAppWebViewController.setWebContentsDebuggingEnabled(true);
  }
  if (status.isGranted) {
    runApp(const MaterialApp(
      home: InAppWebViewScreen(),
    ),);
  } else {
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }
}


class InAppWebViewScreen extends StatefulWidget {
  const InAppWebViewScreen({Key? key}):super(key:key);

  @override
  State<InAppWebViewScreen> createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  String? _currentAddress;
  Position? _currentPosition;
  late final InAppWebViewController webViewController;
  Uri myUrl = Uri.parse('https://fbsports.co.kr/');
  final GlobalKey webViewKey = GlobalKey();
  double progress = 0;
  late InAppWebViewGroupOptions options;
  late PullToRefreshController pullToRefreshController;

  static const platform = MethodChannel('intent');
  @override
  void initState(){
    options = InAppWebViewGroupOptions(
        crossPlatform: InAppWebViewOptions(
          javaScriptEnabled: true,
          javaScriptCanOpenWindowsAutomatically: true,
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
        ),
        android: AndroidInAppWebViewOptions(
          useHybridComposition: true,
        ),
        ios: IOSInAppWebViewOptions(
          allowsInlineMediaPlayback: true,
        ));
    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SafeArea(
            child: WillPopScope(
                onWillPop: () => _goBack(context),
                child: Column(children: <Widget>[
                  progress < 1.0
                      ? LinearProgressIndicator(value: progress, color: Colors.blue)
                      : Container(),
                  Expanded(
                      child: Stack(children: [
                        InAppWebView(
                          key: webViewKey,
                          initialUrlRequest: URLRequest(url: myUrl),
                          shouldOverrideUrlLoading:
                              (controller, NavigationAction navigationAction) async {
                            var uri = navigationAction.request.url!;
                            if (uri.scheme == 'intent') {
                              try {
                                var result = await platform
                                    .invokeMethod('launchKakaoTalk', {'url': uri.toString()});
                                if (result != null) {
                                  await webViewController?.loadUrl(
                                      urlRequest: URLRequest(url: Uri.parse(result)));
                                }

                              } catch (e) {
                                print('url fail $e');
                              }
                              return NavigationActionPolicy.CANCEL;
                            }
                            return NavigationActionPolicy.ALLOW;
                          },
                          initialOptions: InAppWebViewGroupOptions(
                            crossPlatform: InAppWebViewOptions(
                                javaScriptCanOpenWindowsAutomatically: true,
                                javaScriptEnabled: true,
                                useOnDownloadStart: true,
                                useOnLoadResource: true,
                                useShouldOverrideUrlLoading: true,
                                mediaPlaybackRequiresUserGesture: true,
                                allowFileAccessFromFileURLs: true,
                                allowUniversalAccessFromFileURLs: true,

                                verticalScrollBarEnabled: true,
                                userAgent: 'Mozilla/5.0 (Linux; Android 9; LG-H870 Build/PKQ1.190522.001) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/83.0.4103.106 Mobile Safari/537.36'
                            ),
                            android: AndroidInAppWebViewOptions(
                                useHybridComposition: true,
                                allowContentAccess: true,
                                builtInZoomControls: true,
                                thirdPartyCookiesEnabled: true,
                                allowFileAccess: true,
                                supportMultipleWindows: true,

                            ),
                            ios: IOSInAppWebViewOptions(
                              allowsInlineMediaPlayback: true,
                              allowsBackForwardNavigationGestures: true,
                            ),
                          ),
                          onLoadStart: (InAppWebViewController controller, uri) {
                            setState(() {myUrl = uri!;});
                          },
                          onLoadStop: (InAppWebViewController controller, uri) {
                            setState(() {myUrl = uri!;});
                          },
                          androidOnPermissionRequest: (controller, origin, resources) async {
                            return PermissionRequestResponse(
                                resources: resources,
                                action: PermissionRequestResponseAction.GRANT);
                          },
                          onWebViewCreated: (InAppWebViewController controller) async{
                            webViewController = controller;

                            _currentPosition ??= await _getCurrentPosition();
                            controller.addJavaScriptHandler(handlerName: 'getLocation', callback: (args) async{
                              var position = {
                                'lat': _currentPosition?.latitude, 'lon': _currentPosition?.longitude
                              };
                              return position;
                            });
                          },
                          onCreateWindow: (controller, createWindowRequest) async{
                            showDialog(
                              context: context, builder: (context) {
                              return AlertDialog(
                                content: SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: 400,
                                  child: InAppWebView(
                                    // Setting the windowId property is important here!
                                    windowId: createWindowRequest.windowId,
                                    initialOptions: InAppWebViewGroupOptions(
                                      android: AndroidInAppWebViewOptions(
                                        builtInZoomControls: true,
                                        thirdPartyCookiesEnabled: true,
                                      ),
                                      crossPlatform: InAppWebViewOptions(
                                        mediaPlaybackRequiresUserGesture: false,
                                        cacheEnabled: true,
                                        javaScriptEnabled: true,
                                        userAgent: "Mozilla/5.0 (Linux; Android 9; LG-H870 Build/PKQ1.190522.001) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/83.0.4103.106 Mobile Safari/537.36",
                                      ),
                                      ios: IOSInAppWebViewOptions(
                                        allowsInlineMediaPlayback: true,
                                        allowsBackForwardNavigationGestures: true,
                                      ),
                                    ),
                                    onCloseWindow: (controller) async{
                                      if (Navigator.canPop(context)) {
                                        Navigator.pop(context);
                                        Navigator.of(context).popUntil(ModalRoute.withName('/root'));
                                      }
                                    },
                                    onCreateWindow:(controller,action) {
                                      return showDialog(
                                        barrierDismissible: true,
                                        context:context,
                                        builder:(context){
                                          return InAppWebView(
                                            initialOptions:options,
                                            pullToRefreshController: pullToRefreshController,
                                            onWebViewCreated:(controller) async{

                                            }
                                          );
                                        }
                                      );
                                    }
                                  ),
                                ),);
                            },
                            );
                            return true;
                          },
                        )
                      ]))
                ])
            )
        )
    );
  }
  Future<IamportPayment> _payment(BuildContext context) async{
    PaymentData data = PaymentData(
        pg: "payco.AUTOPAY",
        merchantUid: "order_no_123123132", // 상점에서 관리하는 주문 번호
        name: "주문명:결제테스트",
        amount: 50000, //결제금액
        buyerEmail: 'redfila@naver.com',
        buyerName: 'test',
        buyerAddr: 'testasdf',
        buyerTel: '01062080018',
        buyerPostcode: '15703',
        payMethod: '',
        appScheme: ''
    );

    return IamportPayment(
      appBar: AppBar(
        title: Text('아임포트 결제'),
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 24,
          color: Colors.white,
        ),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () {
            Get.back();
          },
        ),
      ),
      initialChild: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/iamport-logo.png'),
              Padding(padding: EdgeInsets.symmetric(vertical: 15)),
              Text('잠시만 기다려주세요...', style: TextStyle(fontSize: 20.0)),
            ],
          ),
        ),
      ),
      userCode: 'imp54100264',
      data: data,
      callback: (Map<String, String> result) {
        Get.offNamed('/payment-result', arguments: result);
      },
    );
  }
  Future<void> _neverSatisfied(BuildContext context) async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('알림'),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('앱을 닫으시겠습니까?'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  exit(0);
                },
              ),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'))
            ],
          );
        });
  }

  Future<bool> _goBack(BuildContext context) async{
    if (await webViewController.canGoBack()) {
      webViewController.goBack();
      return Future.value(false);
    } else {
      Get.toNamed('/payment-test');
      //PaymentTest();
      //_payment(context);
      //_neverSatisfied(context);
      return Future.value(false);
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return false;
    }
    return true;
  }

  Future<Position?> _getCurrentPosition() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      _currentAddress ='${place.street}, ${place.subLocality}, ${place.subAdministrativeArea}, ${place.postalCode}';
    }).catchError((e) {
      debugPrint(e);
    });
  }
}

