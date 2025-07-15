import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thesis/Pages/MobileRecharge/mobileRechargeFinal.dart';
import 'package:thesis/controller/userController.dart';

import '../Components/widgetComponents/textFieldWidget2.dart';
import '../Components/widgetComponents/videoPopup.dart';

class MobileRechargeConfirmScreen extends StatefulWidget {
  final String operator;
  const MobileRechargeConfirmScreen({
    super.key,
    required this.operator,
  });

  @override
  State<MobileRechargeConfirmScreen> createState() =>
      _MobileRechargeConfirmScreenState();
}

class _MobileRechargeConfirmScreenState
    extends State<MobileRechargeConfirmScreen> with TickerProviderStateMixin {
  final userController UserController = Get.put(userController());
  bool _isDrawerOpen = false;
  late StreamSubscription _balanceSubscription;
  Map<String, dynamic>? _userData;
  double _balance = 0.0;
  //Guide System
  late Timer _assistantTimer;
  bool _showAssistantButton = true;
  bool _showPointingAnimation = false;

  late AnimationController _assistantButtonController;
  late AnimationController _pointingController;
  late AnimationController _helpButtonController;
  final ColorTween _helpButtonColorTween = ColorTween(
    begin: Colors.transparent,
    end: Colors.red,
  );

// Add these audio assets to your list
  final String _assistantAppearSound = 'Assets/Audio/assistant_prompt.mp3';

  int _currentStep = 0;
  bool _isGuidedMode = false;
  bool _isFieldHighlighted = false;
  final List<String> _audioInstructions = [
    'Assets/Audio/rechargehelp1.mp3',
    'Assets/Audio/rechargehelp2.mp3',
    'Assets/Audio/sendmoneyhelp3.mp3',
  ];
  //Guide System
  void _startGuide() async {
    final hasValidAgentNumber = UserController.rechargeNum.text.length == 11;
    setState(() {
      _isGuidedMode = true;
      _currentStep = hasValidAgentNumber ? 1 : 0;
      if (hasValidAgentNumber) {
        // Auto-focus amount field if starting at step 1
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context)
              .requestFocus(UserController.rechargeAmountFocus);
        });
      } else {
        // Focus number field if starting at step 0
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(UserController.rechargeNumFocus);
        });
      }
    });

    await _playStepAudio(_currentStep);
    _startHighlightAnimation();
  }

  void _stopGuide() {
    FocusScope.of(context).unfocus();
    setState(() {
      _isGuidedMode = false;
      _currentStep = 0;
      _audioPlayer.stop();
      _showAssistantButton = true;
    });
  }

  Future<void> _playStepAudio(int step) async {
    try {
      await _audioPlayer.setAsset(_audioInstructions[step]);
      await _audioPlayer.play();
      _audioPlayer.playerStateStream.listen((state) {
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
    Future.delayed(Duration(milliseconds: 100), () {
      if (_isGuidedMode) {
        setState(() => _isFieldHighlighted = false);
        _startHighlightAnimation();
      }
    });
  }

  void _handleStepCompletion() {
    if (!_isGuidedMode) return;

    setState(() {
      _currentStep++;

      // Force rebuild before focusing
      if (_currentStep == 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context)
              .requestFocus(UserController.rechargeAmountFocus);
        });
      }
    });

    if (_currentStep < 3) {
      _playStepAudio(_currentStep);
    } else {
      _stopGuide();
    }
  }

  bool _validateNumber(String number) {
    final cleanedNumber = number.replaceAll(RegExp(r'[^\d]'), '');
    final prefix =
        cleanedNumber.length >= 3 ? cleanedNumber.substring(0, 3) : '';

    switch (widget.operator) {
      case 'GrameenPhone':
        return prefix == '017' || prefix == '013';
      case 'Banglalink':
        return prefix == '019' || prefix == '014';
      case 'Robi':
        return prefix == '018';
      case 'Airtel':
        return prefix == '016';
      case 'Teletalk':
        return prefix == '015';
      case 'Citycell':
        return prefix == '011';
      default:
        return false;
    }
  }

  Future<void> _selectContact() async {
    try {
      if (!await FlutterContacts.requestPermission()) {
        Get.snackbar('permissionRequired'.tr, 'contactsPermissionNeeded'.tr);
        return;
      }

      final contact = await FlutterContacts.openExternalPick();
      if (contact == null || contact.phones.isEmpty) return;

      String? phoneNumber;
      if (contact.phones.length > 1) {
        phoneNumber = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('selectNumber'.tr),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: contact.phones
                  .map((phone) => ListTile(
                        title: Text(phone.number),
                        onTap: () => Navigator.pop(context, phone.number),
                      ))
                  .toList(),
            ),
          ),
        );
      } else {
        phoneNumber = contact.phones.first.number;
      }

      if (phoneNumber != null) {
        final cleanedNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
        if (_validateNumber(cleanedNumber)) {
          UserController.rechargeNum.text = cleanedNumber;
        } else {
          Get.snackbar(
            'invalidNumber'.tr,
            'invalidOperatorNumber'.trParams({'operator': widget.operator}),
          );
        }
      }
    } catch (e) {
      Get.snackbar('error'.tr, 'failedToSelectContact'.tr);
    }
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
          TextSpan(text: 'serviceAvailable'.tr + '\n'),
          TextSpan(text: 'transactionFee'.tr + '\n'),
          TextSpan(text: 'maxTransactions'.tr),
        ],
      ),
    );
  }

  void _initBalanceStream() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Create real-time stream
    final userStream = Supabase.instance.client
        .from('users')
        .stream(primaryKey: ['userid'])
        .eq('userid', userId)
        .map((data) => data.first);

    _balanceSubscription = userStream.listen((userData) {
      if (mounted) {
        setState(() {
          _userData = userData;
          _balance = (userData['Balance'] ?? 0.0).toDouble();
        });
      }
    });
  }

  late AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;
  @override
  void initState() {
    userController().dispose();
    super.initState();
    _helpButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _audioPlayer = AudioPlayer();
    _initAudioSession();
    _initBalanceStream();
    _assistantButtonController = AnimationController(
      vsync: this, // This requires TickerProviderStateMixin
      duration: const Duration(seconds: 1),
    );
    _pointingController = AnimationController(vsync: this);
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
    _assistantButtonController.dispose();
    _pointingController.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _balanceSubscription.cancel();
    _assistantTimer.cancel();
    UserController.rechargeNumFocus.dispose();
    UserController.rechargeAmountFocus.dispose();
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

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
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
        children: [
          if (_isGuidedMode)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isFieldHighlighted ? 0.2 : 0.0,
                duration: Duration(milliseconds: 500),
                child: Container(
                  color: Colors.blue,
                ),
              ),
            ),
          SingleChildScrollView(
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
                IgnorePointer(
                  ignoring: _isGuidedMode,
                  child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isDrawerOpen = !_isDrawerOpen;
                        });
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
                ),
                const SizedBox(height: 20),
                Text(
                  'rechargeTo'.trParams({'operator': widget.operator}),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 3,
                        color: _currentStep == 0 && _isGuidedMode
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                    width: MediaQuery.sizeOf(context).width,
                    child: textFieldWidgets2(
                      enabled: !_isGuidedMode || _currentStep == 0,
                      onSubmitted: (value) {
                        if (_isGuidedMode && _currentStep == 0) {
                          if (value.length == 11) {
                            // Valid number
                            _handleStepCompletion();
                          } else if (value.length > 11) {
                            // Prevent over-typing
                            UserController.rechargeNum.text =
                                value.substring(0, 11);
                          }
                        }
                      },
                      hintText: 'mobileNumber'.tr,
                      controller: UserController.rechargeNum,
                      inputType: TextInputType.phone,
                      iconPath: "Assets/Icons/login.svg",
                      obscure: false,
                      focusNode: UserController.rechargeNumFocus,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _isGuidedMode ? null : _selectContact,
                  child: Text(
                    'fromContacts'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(
                  'inputAmount'.tr,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        width: 3,
                        color: _currentStep == 1 && _isGuidedMode
                            ? Colors.red
                            : Colors.black,
                      ),
                    ),
                    width: MediaQuery.sizeOf(context).width,
                    child: textFieldWidgets2(
                      enabled: !_isGuidedMode || _currentStep == 1,
                      onSubmitted: (value) {
                        if (_isGuidedMode && _currentStep == 1) {
                          if (value.isNotEmpty &&
                              double.tryParse(value) != null) {
                            _handleStepCompletion();
                          } else {
                            // Add error feedback
                            _audioPlayer
                                .setAsset('Assets/Audio/wrongamount.mp3');
                            _audioPlayer.play();
                          }
                        }
                      },
                      hintText: 'amount'.tr,
                      controller: UserController.rechargeAmount,
                      inputType: TextInputType.number,
                      iconPath: "Assets/Icons/money2.svg",
                      obscure: false,
                      focusNode: UserController.rechargeAmountFocus,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'availableBalance'.tr,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFE3C2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _userData == null
                      ? const CircularProgressIndicator()
                      : Text(
                          '৳${_balance.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 24),
                        ),
                ),
                AnimatedOpacity(
                  opacity: _currentStep == 2 && _isGuidedMode ? 1.0 : 1.0,
                  duration: Duration(milliseconds: 300),
                  child: Container(
                    width: 200,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            foregroundColor: const Color(0xFFEFE3C2),
                            enableFeedback:
                                _isGuidedMode ? _currentStep == 2 : true,
                          ),
                          onPressed: () {
                            if (_isGuidedMode && _currentStep != 2) return;
                            final number = UserController.rechargeNum.text;
                            final amount = UserController.rechargeAmount.text;

                            if (!_validateNumber(number)) {
                              Get.snackbar(
                                  backgroundColor: Colors.red[200],
                                  'error'.tr,
                                  'invalidOperatorNumber'
                                      .trParams({'operator': widget.operator}));
                              return;
                            }
                            if (number.isEmpty) {
                              Get.snackbar('error'.tr, 'enterReceiverNumber'.tr,
                                  backgroundColor: Colors.red[200]);
                              return;
                            }

                            if (amount.isEmpty) {
                              Get.snackbar('error'.tr, 'enterAmount'.tr,
                                  backgroundColor: Colors.red[200]);
                              return;
                            }

                            final parsedAmount = double.tryParse(amount);
                            if (parsedAmount == null) {
                              Get.snackbar('error'.tr, 'invalidAmount'.tr,
                                  backgroundColor: Colors.red[200]);
                              return;
                            }

                            if (parsedAmount > _balance) {
                              Get.snackbar('error'.tr, 'insufficientBalance'.tr,
                                  backgroundColor: Colors.red[200]);
                              return;
                            }

                            Get.to(MobileRechargefinalScreen(
                                operator: widget.operator,
                                number: number,
                                amount: amount));
                          },
                          icon: const Icon(Icons.arrow_circle_right, size: 80),
                        ),
                        if (_currentStep == 2 && _isGuidedMode)
                          Positioned(
                            left: -20.0,
                            child: IgnorePointer(
                              child: Lottie.asset(
                                'Assets/LOTTIE/pointing.json',
                                width: 100,
                                height: 100,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isDrawerOpen)
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
                            .setAsset('Assets/Audio/Recharge2ndpage.mp3');
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
                          videoAssetPath: 'Assets/Videos/MobileRecharge2.mp4',
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
                                          'Assets/Images/sendMoneyHelp1.png',
                                      title: 'mobileRecharge2Step1title'.tr,
                                      text: 'mobileRecharge2Step1Text'.tr),
                                  const SizedBox(height: 15),
                                  _buildHelpSection(
                                      imagePath:
                                          'Assets/Images/sendMoneyHelp2.png',
                                      title: 'mobileRecharge2Step2title'.tr,
                                      text: 'mobileRecharge2Step2Text'.tr),
                                  const SizedBox(height: 15),
                                  _buildHelpSection(
                                      imagePath:
                                          'Assets/Images/sendMoneyHelp3.png',
                                      title: 'step3Title'.tr,
                                      text: 'step3Desc'.tr),
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
          // Add your drawer implementation from previous code
        ],
      ),
    );
  }
}
