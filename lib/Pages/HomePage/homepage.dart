import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thesis/Pages/Components/allmenus/cashOutMenu.dart';
import 'package:thesis/Pages/Components/allmenus/makePaymentMenu.dart';
import 'package:thesis/Pages/Components/allmenus/mobileRechargemenu.dart';
import 'package:thesis/Pages/Components/allmenus/sendMoneyMenu.dart';
import 'package:thesis/Pages/HomePage/userTransactionPage.dart';
import 'package:thesis/Pages/LoginAndSignUp/loginPage.dart';
import 'package:thesis/services/dbservice.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../controller/languagecontroller.dart';

class sendMoney extends StatefulWidget {
  sendMoney({super.key});

  @override
  State<sendMoney> createState() => _sendMoneyState();
}

class _sendMoneyState extends State<sendMoney> {
  late final RealtimeChannel _userChannel;
  late final Stream<Map<String, dynamic>> _userStream;
  late StreamSubscription _balanceSubscription;
  final authService = dbMethods();
  final String? userId = Supabase.instance.client.auth.currentUser?.id;
  Timer? _popupTimer;
  Map<String, dynamic>? _userData;
  late final String _userId;
  late AudioPlayer _audioPlayer;
  bool _isSoundPlaying = false;
  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser!.id;
    _setupRealTimeUpdates();
    saveOneSignalId(_userId);
    _startPopupTimer();
    _setupRealTimeListener();
    _handleBackgroundNotifications();
    _checkPendingNotifications();
    _initAudio();
  }

  Future<void> _initAudio() async {
    _audioPlayer = AudioPlayer();

    // Configure audio session with proper settings
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.mixWithOthers,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.sonification,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.assistanceSonification,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
      androidWillPauseWhenDucked: true,
    ));

    // Preload the dialog audio
    await _audioPlayer.setAsset('Assets/Audio/dialogAudio.mp3');
  }

  void _handleBackgroundNotifications() {
    // Clear fields when notification is received in background
    OneSignal.Notifications.addClickListener((event) {
      _clearNotificationFields();
    });

    // Clear fields when notification is received while app is closed
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      _clearNotificationFields();
    });
  }

  Future<void> _checkPendingNotifications() async {
    // Check for pending notifications when app starts
    final response = await Supabase.instance.client
        .from('users')
        .select('last_notification_time, last_received_amount')
        .eq('userid', _userId)
        .single();

    if (response['last_received_amount'] != null) {
      final notificationTime =
          DateTime.parse(response['last_notification_time']);
      if (DateTime.now().difference(notificationTime).inMinutes < 1) {
        Get.snackbar(
          'Money Received!',
          'You got ৳${response['last_received_amount'].toStringAsFixed(2)}',
          snackPosition: SnackPosition.TOP,
          backgroundColor: const Color(0xFFEFE3C2),
          colorText: Colors.black,
        );
      }
      await _clearNotificationFields();
    }
  }

  Future<void> _clearNotificationFields() async {
    await Supabase.instance.client.from('users').update({
      'last_received_amount': null,
      'last_notification_time': null,
    }).eq('userid', _userId);
  }

  void _setupRealTimeListener() {
    final userId = Supabase.instance.client.auth.currentUser!.id;

    // Create a channel
    _userChannel = Supabase.instance.client.channel('user_$userId');

    // Listen to specific updates
    _userChannel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'users',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'userid',
        value: userId,
      ),
      callback: (payload) async {
        final newAmount = payload.newRecord['last_received_amount'];
        final notificationTime = payload.newRecord['last_notification_time'];
        if (newAmount != null) {
          final timeDifference =
              DateTime.now().difference(DateTime.parse(notificationTime));
          if (timeDifference.inMinutes < 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              Get.snackbar(
                'Money Received!',
                'You got ৳${newAmount.toStringAsFixed(2)}',
                snackPosition: SnackPosition.TOP, // Add this line
                backgroundColor: const Color(0xFFEFE3C2),
                colorText: Colors.black,
                margin: const EdgeInsets.only(
                    top: 20), // Add margin for better spacing
              );
              await _clearNotificationFields();

              // Clear the notification
            });
          }
        }
      },
    );

    // Subscribe to the channel
    _userChannel.subscribe();
  }

  void saveOneSignalId(String userId) async {
    final playerId = await OneSignal.User.pushSubscription.id;

    if (playerId != null) {
      await Supabase.instance.client
          .from('users')
          .update({'onesignal_id': playerId}).eq('userid', userId);
    }
  }

  Future<void> sendNotificationToReceiver(
      String receiverNumber, String TransAmount) async {
    try {
      // Get OneSignal ID of the receiver
      final response = await Supabase.instance.client
          .from('users')
          .select('onesignal_id')
          .eq('Number', receiverNumber)
          .single();

      final receiverOneSignalId = response['onesignal_id'];

      if (receiverOneSignalId != null && receiverOneSignalId.isNotEmpty) {
        final notificationUrl =
            Uri.parse('https://onesignal.com/api/v1/notifications');

        final headers = {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization':
              'Basic os_v2_app_uvgnx7c6rfgxndenpbegzgw7xy3jueubrouueymmhrbyz4blfdcdv5u4ijziu5t32cntdqc5etwp5idj4aows7oslmytp35g2vwh56q',
        };

        final body = {
          "app_id":
              "a54cdbfc-5e89-4d76-8c8d-78486c9adfbe", // Replace with your app ID
          "include_player_ids": [receiverOneSignalId],
          "headings": {"en": "Money Received"},
          "contents": {"en": "You have received ${TransAmount}৳ Taka"},
          "data": {
            "clear_notification": true,
            "timestamp": DateTime.now().toIso8601String(),
          } // Leave content blank for now
        };

        final response = await http.post(
          notificationUrl,
          headers: headers,
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          print("Notification sent to receiver");
        } else {
          print("Failed to send notification: ${response.body}");
        }
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  void _setupRealTimeUpdates() {
    // Create real-time stream
    _userStream = Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['userid'])
        .eq('userid', _userId)
        .map((data) => data.first);

    // Listen to changes
    _balanceSubscription = _userStream.listen((userData) {
      if (mounted) {
        setState(() {
          _userData = userData;
        });
      }
    });
  }

  void _startPopupTimer() {
    _popupTimer = Timer(Duration(seconds: 5), () {
      _checkBooleanStatus();
    });
  }

  Future<void> _checkBooleanStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('Transaction')
          .select('senderflag')
          .eq('sendersId', user.id)
          .single();

      if (response['senderflag'] == false) {
        _showConfirmationDialog();
      }
    } catch (e) {
      print('Error checking status: $e');
    }
  }

  void _showConfirmationDialog() async {
    final user = Supabase.instance.client.auth.currentUser;
    final transactionResponse = await Supabase.instance.client
        .from('Transaction')
        .select('receiver, amount')
        .eq('sendersId', user!.id)
        .order('created_at', ascending: false)
        .limit(1)
        .single();
    final receiverNumber = transactionResponse['receiver'] as String;
    final transactionAmount = transactionResponse['amount'].toString();
    final parsedAmount = double.parse(transactionAmount);

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              // Ensure audio session is active
              final session = await AudioSession.instance;
              await session.setActive(true);

              // Reset player and play audio
              await _audioPlayer.stop();
              await _audioPlayer.seek(Duration.zero);
              await _audioPlayer.play();
            } catch (e) {
              print("Error playing sound: $e");
            }
          });
          bool isProcessing = false;
          return StatefulBuilder(builder: (dialogContext, setState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.all(20),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              title: Center(
                  child: Text(
                'confirmSend'.tr,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              )),
              content: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width *
                      0.8, // 80% of screen width// Fixed height
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 50, color: Colors.amber),
                      const SizedBox(height: 15),
                      Text(
                        'confirmSendMessage'.trParams({
                          'amount': parsedAmount.toStringAsFixed(2),
                          'number': receiverNumber,
                        }),
                        style: const TextStyle(fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: () async {
                                _audioPlayer.stop();
                                Navigator.pop(dialogContext);
                                await _handleReject();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Send Money Rejected')),
                                );
                                Navigator.pop(context);
                              },
                              child: Text('reject'.tr,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16)),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade400,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      setState(() => isProcessing = true);
                                      _audioPlayer.stop();
                                      Navigator.pop(dialogContext);

                                      try {
                                        await _updateBooleanStatus();
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('Send Money Accepted')),
                                        );
                                      } catch (e) {
                                        Navigator.pop(context); // Close loading
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(content: Text('Error: $e')),
                                        );
                                      }
                                    },
                              child: Text(
                                'accept'.tr,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  Future<void> _stopAudio() async {
    if (_isSoundPlaying) {
      try {
        await _audioPlayer.stop();
        _isSoundPlaying = false;
      } catch (e) {
        print("Error stopping audio: $e");
      }
    }
  }

  Future<void> _handleReject() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      final transactionResponse = await Supabase.instance.client
          .from('Transaction')
          .select('transId , amount')
          .eq('sendersId', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .single();
      final transactionId = transactionResponse['transId'] as String;
      final transactionAmount =
          double.parse(transactionResponse['amount'].toString());

      // Get receiver's current balance
      final receiverResponse = await Supabase.instance.client
          .from('users')
          .select('Balance')
          .eq('userid', user.id)
          .single();

      final currentBalance =
          double.parse(receiverResponse['Balance'].toString());
      final newBalance = currentBalance + transactionAmount;

      await Supabase.instance.client
          .from('users')
          .update({'Balance': newBalance}).eq('userid', user.id);
      await Supabase.instance.client
          .from('Transaction')
          .delete()
          .eq('transId', transactionId);
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  Future<void> _updateBooleanStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      //Get latest Transaction
      final transactionResponse = await Supabase.instance.client
          .from('Transaction')
          .select('transId , receiver, amount')
          .eq('sendersId', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .single();

      final transactionId = transactionResponse['transId'] as String;

      //Delete Transaction Table
      await Supabase.instance.client
          .from('Transaction')
          .delete()
          .eq('transId', transactionId);
      final receiverNumber = transactionResponse['receiver'] as String;
      final transactionAmount =
          double.parse(transactionResponse['amount'].toString());

      // Get receiver's current balance
      final receiverResponse = await Supabase.instance.client
          .from('users')
          .select('userid , Balance')
          .eq('Number', receiverNumber)
          .single();
      final newBalance = double.parse(receiverResponse['Balance'].toString()) +
          transactionAmount;
      await Supabase.instance.client
          .from('users')
          .update({'Balance': newBalance}).eq('Number', receiverNumber);
      //Getting Senders Number
      final senderResponse = await Supabase.instance.client
          .from('users')
          .select('Number')
          .eq('userid', user.id)
          .single();
      final senderNumber = senderResponse['Number'] as String;

      final receiverId = receiverResponse['userid'] as String;

      await sendNotificationToReceiver(
          receiverNumber, transactionAmount.toString());

      await Supabase.instance.client.from('users').update({
        'last_received_amount': transactionAmount,
        'last_notification_time': DateTime.now().toIso8601String(),
      }).eq('Number', receiverNumber);
      //userTransactiontable insert for sender
      await Supabase.instance.client.from('user_transactions').insert({
        'userid': user.id,
        'receiverNum': receiverNumber,
        'receiverAmount': transactionAmount,
        'transId': transactionId,
        'type': 'Send Money',
        'time': DateTime.now().toIso8601String(),
      });
      //userTransactiontable insert for receiver
      await Supabase.instance.client.from('user_transactions').insert({
        'userid': receiverId,
        'receiverNum': senderNumber,
        'receiverAmount': transactionAmount,
        'transId': transactionId,
        'type': 'Received Money',
        'time': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating status: $e');
    }
  }

  void signOut() async {
    try {
      await authService.signOut();
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        Get.offAll(loginScreen());
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _balanceSubscription.cancel();
    _popupTimer?.cancel();
    _userChannel.unsubscribe();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
        endDrawer: Drawer(
            elevation: 5,
            child: Container(
              color: const Color(0xFFEFE3C2),
              child: ListView(padding: const EdgeInsets.all(0), children: [
                DrawerHeader(
                    decoration: const BoxDecoration(),
                    child: UserAccountsDrawerHeader(
                        accountName: Text(
                          _userData!['Name'].toString(),
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.w800),
                        ),
                        accountEmail: Text(
                          _userData!['Number'].toString(),
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontWeight: FontWeight.w600),
                        ))),
                const SizedBox(
                  height: 20,
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: Text('yourActivity'.tr),
                  onTap: () {
                    Get.to(() => TransactionsPage());
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text('logout'.tr),
                  onTap: signOut,
                ),
              ]),
            )),
        appBar: AppBar(
          title: Text(
            'appTitle'.tr,
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          backgroundColor: const Color(0xFF85A947),
        ),
        backgroundColor: const Color(0xFF85A947),
        body: SafeArea(
          child: Container(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Container(
                              height: 60,
                              width: 150,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFE3C2),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.4),
                                    spreadRadius: 2,
                                    blurRadius: 6,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "৳ ${(_userData!['Balance'] ?? 0.0).toStringAsFixed(2)}",
                                  style: const TextStyle(fontSize: 20),
                                ),
                              )),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'balance'.tr,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            Text(
                              'EN',
                              style: TextStyle(
                                color: Get.locale?.languageCode == 'en'
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Obx(() {
                              final langController =
                                  Get.find<LanguageController>();
                              return Switch(
                                value: langController
                                        .currentLocale.value.languageCode ==
                                    'bn',
                                activeColor: Colors.white,
                                activeTrackColor: Colors.green[700],
                                inactiveThumbColor: const Color(0xFF85A947),
                                inactiveTrackColor: const Color(0xFFEFE3C2),
                                onChanged: (value) {
                                  final newLocale = value
                                      ? const Locale('bn', 'BD')
                                      : const Locale('en', 'US');
                                  langController.changeLanguage(newLocale);
                                },
                              );
                            }),
                            Text(
                              'বাং',
                              style: TextStyle(
                                color: Get.locale?.languageCode == 'bn'
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                ),
                Container(
                  width: MediaQuery.of(context).size.width * 0.92,
                  height: MediaQuery.of(context).size.height * 0.18,
                  decoration: BoxDecoration(
                    color: Color(0xFFEFE3C2),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        Lottie.asset(
                          "Assets/LOTTIE/hello.json",
                          height: 100,
                          width: 100,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome'.tr,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5),
                              Flexible(
                                child: Text(
                                  "${_userData!['Name']}",
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 50,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CarouselSlider(
                        unlimitedMode: true,
                        slideTransform: const CubeTransform(),
                        viewportFraction: 1,
                        initialPage: 4,
                        autoSliderDelay: const Duration(seconds: 5),
                        children: [
                          if (_userData != null) // Add null check
                            sendMoneyMenu(
                              balance: _userData!['Balance'].toString(),
                            ),
                          const cashOutMenu(),
                          const mobileRechargeMenu(),
                          const makePaymentMenu()
                        ]),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
