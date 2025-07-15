import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';

import '../Components/widgetComponents/videoPopup.dart';
import 'mobileRechargeConfirm.dart';

class MobileRechargeScreen extends StatefulWidget {
  const MobileRechargeScreen({super.key});

  @override
  State<MobileRechargeScreen> createState() => _MobileRechargeScreenState();
}

class _MobileRechargeScreenState extends State<MobileRechargeScreen>
    with TickerProviderStateMixin {
  bool _isDrawerOpen = false;
  String _selectedOperator = '';
  late AudioPlayer _audioPlayer;
  int _currentStep = 0;
  bool _isGuidedMode = false;
  bool _isFieldHighlighted = false;
  late AnimationController _assistantButtonController;
  late AnimationController _pointingController;
  late AnimationController _helpButtonController;
  final ColorTween _helpButtonColorTween = ColorTween(
    begin: Colors.transparent,
    end: Colors.red,
  );
  late Timer _assistantTimer;
  bool _showAssistantButton = true;
  bool _showPointingAnimation = false;
  final List<String> _audioInstructions = [
    'Assets/Audio/select_operator.mp3',
    'Assets/Audio/press_continue.mp3',
  ];
  late AudioPlayer _guideAudioPlayer;
  final String _assistantAppearSound = 'Assets/Audio/assistant_prompt.mp3';

  final List<Map<String, dynamic>> operators = [
    {'icon': 'Assets/Icons/gp.svg', 'name': 'GrameenPhone'},
    {'icon': 'Assets/Icons/bl.svg', 'name': 'Banglalink'},
    {'icon': 'Assets/Icons/atl.svg', 'name': 'Airtel'},
    {'icon': 'Assets/Icons/robi.svg', 'name': 'Robi'},
    {'icon': 'Assets/Icons/ttl.svg', 'name': 'Teletalk'},
    {'icon': 'Assets/Icons/ccl2.svg', 'name': 'Citycell'},
  ];
  @override
  void initState() {
    super.initState();
    _helpButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _audioPlayer = AudioPlayer();
    _initAudioSession();
    _guideAudioPlayer = AudioPlayer();
    _pointingController = AnimationController(vsync: this);
    _assistantButtonController = AnimationController(vsync: this);
    _assistantTimer = Timer(Duration(seconds: 20), () {
      if (mounted && !_isGuidedMode && !_isDrawerOpen) {
        setState(() {
          _showPointingAnimation = true;
        });
        _playAssistantPrompt();
      }
    });
  }

  @override
  void dispose() {
    _guideAudioPlayer.stop();
    _guideAudioPlayer.dispose();
    _pointingController.dispose();
    _assistantButtonController.dispose();

    _assistantTimer.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _helpButtonController.dispose();
    super.dispose();
  }

  Future<void> _playAssistantPrompt() async {
    try {
      await _audioPlayer.setAsset(_assistantAppearSound);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing assistant prompt: $e');
    }
  }

  //Guide Mode
  void _startGuide() async {
    setState(() {
      _isGuidedMode = true;
      _currentStep = 0;
    });
    await _playStepAudio(0);
  }

  void _stopGuide() {
    setState(() {
      _isGuidedMode = false;
      _currentStep = 0;
      _showAssistantButton = true;
    });
    _guideAudioPlayer.stop();
  }

  Future<void> _playStepAudio(int step) async {
    try {
      await _guideAudioPlayer.setAsset(_audioInstructions[step]);
      await _guideAudioPlayer.play();
      _guideAudioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          if (step == 0) _startHighlightAnimation();
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

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
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
              style: const TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: 'serviceAvailable'.tr + '\n'),
          TextSpan(text: 'transactionFee'.tr + '\n'),
          TextSpan(text: 'maxTransactions'.tr),
        ],
      ),
    );
  }

  bool _isAudioPlaying = false;

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
        title: Text(
          'mobileRecharge'.tr,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFFEFE3C2),
        actions: [
          if (_isGuidedMode)
            IconButton(
              icon: Lottie.asset('Assets/LOTTIE/stophelp.json'),
              onPressed: _stopGuide,
            ),
          Visibility(
            visible: _showAssistantButton,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: _showPointingAnimation,
                  child: Lottie.asset(
                    'Assets/LOTTIE/pointing.json',
                    controller: _pointingController,
                    width: 80,
                    height: 80,
                    repeat: true,
                    onLoaded: (composition) {
                      _pointingController
                        ..duration = composition.duration
                        ..repeat();
                    },
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  icon: Lottie.asset(
                    'Assets/LOTTIE/assistedbutton.json',
                    controller: _assistantButtonController,
                    width: 40,
                    height: 40,
                    repeat: true,
                    onLoaded: (composition) {
                      _assistantButtonController
                        ..duration = composition.duration
                        ..repeat();
                    },
                  ),
                  onPressed: () {
                    // Hide both elements
                    setState(() {
                      _showAssistantButton = false;
                      _showPointingAnimation = false;
                    });
                    // Stop animations
                    _pointingController.stop();
                    _assistantButtonController.stop();
                    // Start guide
                    _startGuide();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'needHelp'.tr,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800),
                ),
                GestureDetector(
                    onTap: () {
                      setState(() => _isDrawerOpen = !_isDrawerOpen);
                    },
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
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF85A947),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      width: 3,
                      color: _isGuidedMode && _currentStep == 0
                          ? Colors.red
                          : Colors.black,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_android, color: Colors.black),
                      const SizedBox(width: 15),
                      Text(
                        _selectedOperator.isEmpty
                            ? 'SelectOperator'.tr
                            : _selectedOperator,
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedOperator.isEmpty
                              ? Colors.black
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE3C2),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.4),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(6, 17),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate sizes based on available width
                        final screenWidth = MediaQuery.of(context).size.width;
                        final iconSize =
                            screenWidth * 0.08; // 12% of screen width
                        final fontSize =
                            screenWidth * 0.03; // 3% of screen width
                        final boxPadding = screenWidth * 0.010;

                        return Column(
                          children: [
                            Text(
                              'SelectOperator'.tr,
                              style: TextStyle(
                                fontSize:
                                    fontSize * 1.5, // 4.5% of screen width
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 1.0,
                                mainAxisSpacing: screenWidth * 0.03,
                                crossAxisSpacing: screenWidth * 0.03,
                              ),
                              itemCount: operators.length,
                              itemBuilder: (context, index) {
                                bool isSelected = _selectedOperator ==
                                    operators[index]['name'];
                                return Container(
                                  margin: EdgeInsets.all(boxPadding),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _isGuidedMode && _currentStep == 0
                                          ? Colors.yellow
                                          : isSelected
                                              ? Color(0xFF5F7A32)
                                              : Colors.grey.shade300,
                                      width: _isGuidedMode && _currentStep == 0
                                          ? 3
                                          : (isSelected ? 2 : 1),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ],
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      if (_isGuidedMode && _currentStep != 0)
                                        return;
                                      setState(() {
                                        _selectedOperator =
                                            operators[index]['name'];
                                        if (_isGuidedMode) {
                                          _currentStep = 1;
                                          _playStepAudio(1);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(boxPadding * 2),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(boxPadding),
                                            child: SvgPicture.asset(
                                              operators[index]['icon'],
                                              height: iconSize,
                                              width: iconSize,
                                            ),
                                          ),
                                          SizedBox(height: boxPadding),
                                          Text(
                                            operators[index]['name'],
                                            style: TextStyle(
                                              fontSize: fontSize,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFF85A947),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.4),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(3, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: Icon(
                      Icons.arrow_forward,
                      color: _selectedOperator.isEmpty
                          ? Colors.white
                          : Colors.black,
                    ),
                    label: Text(
                      'Continue'.tr,
                      style: TextStyle(
                          color: _selectedOperator.isEmpty
                              ? Colors.white
                              : Colors.black,
                          fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEFE3C2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    onPressed: (_isGuidedMode && _currentStep != 1) ||
                            _selectedOperator.isEmpty
                        ? null
                        : () {
                            _assistantTimer.cancel();
                            _audioPlayer.stop();
                            _guideAudioPlayer.stop();
                            if (_isGuidedMode) _stopGuide();
                            Get.to(MobileRechargeConfirmScreen(
                                operator: _selectedOperator));
                          },
                  ),
                ),
              ],
            ),
          ),
          // Drawer code remains the same
          if (_isDrawerOpen)
            GestureDetector(
              onTap: () => setState(() => _isDrawerOpen = false),
              child: Container(color: Colors.black54.withOpacity(0.3)),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            right: _isDrawerOpen ? 0 : -80,
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
                            .setAsset('Assets/Audio/recharge1stpage.mp3');
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
                          videoAssetPath: 'Assets/Videos/MobileRecharge1.mp4',
                        ),
                      );
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
                          insetPadding: EdgeInsets.all(20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          title: const Center(
                            child: Text(
                              'Text Help Guide',
                              style: TextStyle(
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
                                          'Assets/Images/mobileRechargepage1step1.png',
                                      title: 'mobileRecharge1Step1title'.tr,
                                      text: 'mobileRecharge1Step1Text'.tr),
                                  const SizedBox(height: 15),
                                  _buildHelpSection(
                                      imagePath:
                                          'Assets/Images/mobileRechargepage1step2.png',
                                      title: 'mobileRecharge1Step2Title'.tr,
                                      text: 'mobileRecharge1step2Text'.tr),
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
        ],
      ),
    );
  }
}
