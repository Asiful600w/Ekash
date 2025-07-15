import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thesis/Pages/Components/widgetComponents/confirmButton.dart';
import 'package:thesis/Pages/Components/widgetComponents/confirmpintextfield.dart';
import 'package:thesis/Pages/HomePage/homepage.dart';
import 'package:thesis/Pages/MobileRecharge/mobileRechargeInfo.dart';
import 'package:thesis/services/dbservice.dart';
import 'package:xid/xid.dart';

import '../Components/widgetComponents/videoPopup.dart';

class MobileRechargefinalScreen extends StatefulWidget {
  final String operator;
  final String number;
  final String amount;
  const MobileRechargefinalScreen({
    super.key,
    required this.operator,
    required this.number,
    required this.amount,
  });

  @override
  State<MobileRechargefinalScreen> createState() =>
      _MobileRechargefinalScreenState();
}

class _MobileRechargefinalScreenState extends State<MobileRechargefinalScreen>
    with TickerProviderStateMixin {
  bool _isProcessing = false;
  late AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;
  final authService = dbMethods();
  final String? userId = Supabase.instance.client.auth.currentUser?.id;
  Map<String, dynamic>? _userData;
  late List<TextEditingController> _pinControllers;
  late List<FocusNode> _pinFocusNodes;
  bool _isDrawerOpen = false;
  Timer? _holdTimer;
  int _currentStep = 0;
  bool _isGuidedMode = false;
  bool _isFieldHighlighted = false;
  final List<String> _audioInstructions = [
    'Assets/Audio/interactivehelppin.mp3',
    'Assets/Audio/interactivehelpconfirm.mp3',
  ];
  late AudioPlayer _guideAudioPlayer;
  late AnimationController _helpButtonController;
  final ColorTween _helpButtonColorTween = ColorTween(
    begin: Colors.transparent,
    end: Colors.red,
  );
  void _startGuide() async {
    setState(() {
      _isGuidedMode = true;
      _currentStep = 0;
    });
    FocusScope.of(context).requestFocus(_pinFocusNodes[0]);
    await _playStepAudio(0);
    _startHighlightAnimation();
  }

  void _stopGuide() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isGuidedMode = false;
      _currentStep = 0;
      _guideAudioPlayer.stop();
    });
  }

  Future<void> _playStepAudio(int step) async {
    try {
      await _guideAudioPlayer.setAsset(_audioInstructions[step]);
      await _guideAudioPlayer.play();
      _guideAudioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          _startHighlightAnimation();
        }
      });
    } catch (e) {
      print('Audio error: $e');
    }
  }

  void _startHighlightAnimation() {
    setState(() => _isFieldHighlighted = true);
    Future.delayed(Duration(milliseconds: 500), () {
      if (_isGuidedMode) {
        setState(() => _isFieldHighlighted = false);
        _startHighlightAnimation();
      }
    });
  }

  void _handleStepCompletion() {
    if (!_isGuidedMode) return;

    setState(() => _currentStep++);

    if (_currentStep < 2) {
      _playStepAudio(_currentStep);
      if (_currentStep == 1) {
        // Auto-focus the first PIN field when entering step 0
        FocusScope.of(context).unfocus();
      }
    } else {
      _stopGuide();
    }
  }

  @override
  void initState() {
    super.initState();
    _helpButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _audioPlayer = AudioPlayer();
    _guideAudioPlayer = AudioPlayer();
    _initAudioSession();
    _loadUserData();
    _pinControllers = List.generate(5, (index) => TextEditingController());
    _pinFocusNodes = List.generate(5, (index) => FocusNode());
  }

  Future<void> _loadUserData() async {
    final data = await dbMethods.getUserData(userId!);
    setState(() => _userData = data);
  }

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    for (var node in _pinFocusNodes) {
      node.dispose();
    }
    _helpButtonController.dispose();
    super.dispose();
    super.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
  }

  void _handlePinEntered(String pin) {
    print('Entered PIN: $pin');
  }

  Widget _buildHelpSection(
      {required String imagePath,
      required String title,
      required String text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF28390B)),
        ),
        const SizedBox(height: 5),
        Text(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildNoteText() {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 14, color: Colors.red, fontStyle: FontStyle.italic),
        children: [
          TextSpan(
              text: 'importantNotes'.tr + '\n',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: 'note1'.tr + '\n'),
          TextSpan(text: 'note2'.tr + '\n'),
          TextSpan(text: 'note3'.tr),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDrawerOpen && !_isGuidedMode) {
      _helpButtonController.repeat(reverse: true);
    } else {
      _helpButtonController.stop();
      _helpButtonController.value = 0;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('mobileRecharge'.tr),
        backgroundColor: const Color(0xFFEFE3C2),
        actions: [
          if (_isGuidedMode)
            IconButton(
              icon: Lottie.asset('Assets/LOTTIE/stophelp.json'),
              onPressed: _stopGuide,
            ),
          IconButton(
            icon: Lottie.asset('Assets/LOTTIE/assistedbutton.json'),
            onPressed: _startGuide,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Text('needHelp'.tr,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                IgnorePointer(
                  ignoring: _isGuidedMode,
                  child: GestureDetector(
                      onTap: () =>
                          setState(() => _isDrawerOpen = !_isDrawerOpen),
                      child: AnimatedBuilder(
                          animation: _helpButtonController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                  color: const Color(0xFFEFE3C2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _helpButtonColorTween
                                        .evaluate(_helpButtonController)!,
                                    width: 2.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      spreadRadius: 2,
                                      blurRadius: 6,
                                      offset: Offset(0, 5),
                                    ),
                                  ]),
                              margin: const EdgeInsets.only(top: 5),
                              child: Lottie.asset('Assets/LOTTIE/help3.json',
                                  height: 70, width: 70 // Your animation path
                                  ),
                            );
                          })),
                ),
                const SizedBox(height: 20),
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.4,
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE3C2),
                    borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.width * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 3,
                        blurRadius: 10,
                        offset: const Offset(5, 8),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final baseFontSize = constraints.maxHeight * 0.055;
                      final verticalSpacing = constraints.maxHeight * 0.02;

                      return SingleChildScrollView(
                        padding:
                            EdgeInsets.symmetric(vertical: verticalSpacing),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: verticalSpacing),
                              child: AutoSizeText(
                                'numberLabel'
                                    .trParams({'number': widget.number}),
                                style: TextStyle(
                                  fontSize: baseFontSize * 0.6,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                minFontSize: 12,
                              ),
                            ),
                            Divider(
                              thickness: baseFontSize * 0.12,
                              color: Colors.black,
                              indent: constraints.maxWidth * 0.05,
                              endIndent: constraints.maxWidth * 0.05,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: verticalSpacing),
                              child: AutoSizeText(
                                'amountLabel'
                                    .trParams({'amount': widget.amount}),
                                style: TextStyle(
                                  fontSize: baseFontSize * 0.6,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                minFontSize: 12,
                              ),
                            ),
                            Divider(
                              thickness: baseFontSize * 0.12,
                              color: Colors.black,
                              indent: constraints.maxWidth * 0.05,
                              endIndent: constraints.maxWidth * 0.05,
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: verticalSpacing),
                              child: AutoSizeText(
                                'confirmRecharge'.tr,
                                style: TextStyle(
                                  fontSize: baseFontSize * 0.7,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                minFontSize: 14,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: constraints.maxWidth * 0.04,
                                vertical: verticalSpacing,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * 0.9,
                                  maxHeight: constraints.maxHeight * 0.18,
                                ),
                                child: PinTextField(
                                  pinLength: 5,
                                  controllers: _pinControllers,
                                  focusNodes: _pinFocusNodes,
                                  onPinEntered: (pin) {
                                    if (_isGuidedMode && _currentStep == 0) {
                                      _handleStepCompletion();
                                    }
                                    _handlePinEntered(pin);
                                  },
                                  fieldWidth: constraints.maxWidth * 0.14,
                                  fieldHeight: constraints.maxHeight * 0.08,
                                  textStyle: TextStyle(
                                    fontSize: baseFontSize * 0.8,
                                  ),
                                  onChanged: (index, value) {
                                    if (_isGuidedMode && _currentStep == 0) {
                                      // Handle guided mode progression
                                      if (value.isNotEmpty) {
                                        if (index < 4) {
                                          // Auto-focus next field after short delay
                                          Future.delayed(
                                              Duration(milliseconds: 50), () {
                                            FocusScope.of(context).requestFocus(
                                                _pinFocusNodes[index + 1]);
                                          });
                                        }
                                        // Check if all fields are filled
                                        if (_pinControllers
                                            .every((c) => c.text.isNotEmpty)) {
                                          FocusScope.of(context).unfocus();
                                          _handleStepCompletion();
                                        }
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
              ],
            ),
          ),
          if (_isDrawerOpen && !_isGuidedMode)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDrawerOpen = false;
                });
              },
              child: Container(
                color: Colors.black54.withOpacity(0.3),
              ),
            ),
          if (_isGuidedMode)
            IgnorePointer(
              ignoring: _currentStep != 0, // Only allow PIN field interaction
              child: Container(color: Colors.transparent),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isDrawerOpen ? 0 : -80, // Adjust based on drawer width
            top: 80,
            child: Container(
              width: 80,
              height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFEFE3C2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: SvgPicture.asset(
                      "Assets/Icons/audiohelp.svg",
                      height: 30,
                      width: 10,
                    ),
                    onPressed: () async {
                      try {
                        setState(() => _isAudioPlaying = true);
                        await _audioPlayer
                            .setAsset('Assets/Audio/Recharge3rdpage.mp3');
                        await _audioPlayer.play();
                        _audioPlayer.playerStateStream.listen((state) {
                          if (state.processingState ==
                              ProcessingState.completed) {
                            setState(() => _isAudioPlaying = false);
                          }
                        });
                      } catch (e) {
                        setState(() => _isAudioPlaying = false);
                        print('Error playing audio: $e');
                      }
                    },
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      "Assets/Icons/videohelp.svg",
                      height: 35,
                      width: 20,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const VideoHelpPopup(
                          videoAssetPath:
                              'Assets/Videos/mobileRechargeconfirm.mp4',
                        ),
                      );
                      // Handle second button press
                    },
                  ),
                  IconButton(
                    icon: SvgPicture.asset(
                      "Assets/Icons/texthelp.svg",
                      height: 30,
                      width: 20,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          insetPadding: const EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: Center(
                            child: Text(
                              'textHelpGuide'.tr,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF28390B),
                              ),
                            ),
                          ),
                          content: SingleChildScrollView(
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHelpSection(
                                      imagePath:
                                          'Assets/Images/mobileRechargepage3step1.png',
                                      title: 'step12Title1'.tr,
                                      text: 'mobileRecharge3Step1Text'.tr),
                                  const SizedBox(height: 15),
                                  _buildHelpSection(
                                      imagePath:
                                          'Assets/Images/sendMoneyHelp5.png',
                                      title: 'step22Title'.tr,
                                      text: 'step2Text'.tr),
                                  const SizedBox(height: 15),
                                  _buildHelpSection(
                                      imagePath:
                                          'Assets/Images/sendMoneyHelp6.png',
                                      title: 'step3Title'.tr,
                                      text: 'step3Text'.tr),
                                  const SizedBox(height: 20),
                                  _buildNoteText(),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF28390B),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 30, vertical: 12),
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        'closeGuide'.tr,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _isAudioPlaying = false;
                        _audioPlayer.stop();
                        _isDrawerOpen = false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isAudioPlaying)
            Positioned(
              bottom: 20,
              right: 20,
              child: Lottie.asset(
                'Assets/LOTTIE/audioplaying.json',
                width: 80,
                height: 80,
                animate: true,
              ),
            ),
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Lottie.asset(
                    'Assets/LOTTIE/transLoad.json', // Your animation path
                    width: 200,
                    height: 200,
                    repeat: true,
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: IgnorePointer(
          ignoring: _isGuidedMode && _currentStep == 0,
          child: Stack(
            children: [
              ParabolicButton(
                onPressed: () async {
                  final enteredPin = _pinControllers.map((c) => c.text).join();
                  if (enteredPin != _userData!['Pin']) {
                    Get.snackbar('error'.tr, 'wrongPin'.tr,
                        backgroundColor: Colors.red[200]);
                    return;
                  }

                  setState(() => _isProcessing = true);
                  _holdTimer = Timer(const Duration(seconds: 3), () async {
                    try {
                      final transId = Xid().toString();
                      final oldBalance =
                          double.parse(_userData!['Balance'].toString());
                      final rechargeAmount = double.parse(widget.amount);
                      final newBalance = oldBalance - rechargeAmount;
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) return;

                      await authService.updateBalance(newBalance);
                      await Supabase.instance.client
                          .from('user_transactions')
                          .insert({
                        'userid': user.id,
                        'receiverNum': widget.number,
                        'receiverAmount': double.parse(widget.amount),
                        'transId': transId,
                        'type': 'Mobile Recharge',
                        'time': DateTime.now().toIso8601String(),
                      });

                      Get.offAll(MobileRechargeDetailPage(
                          transactionId: transId,
                          operator: widget.operator,
                          mobileNumber: widget.number,
                          rechargeAmount: double.parse(widget.amount),
                          currentBalance: newBalance));
                    } catch (e) {
                      setState(() => _isProcessing = false);
                      Get.snackbar('error'.tr, 'rechargeFailed'.tr);
                    }
                  });
                },
              ),
              if (_isGuidedMode && _currentStep == 1)
                Positioned(
                  child: Lottie.asset(
                    'Assets/LOTTIE/pointing.json', // Your animation path
                    width: 120,
                    height: 120,
                    repeat: true,
                  ),
                ),
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
