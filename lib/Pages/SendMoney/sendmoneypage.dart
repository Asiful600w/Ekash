import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thesis/Pages/SendMoney/sendMoneyConfirm.dart';
import 'package:thesis/controller/userController.dart';
import 'package:get/get.dart';
import '../Components/widgetComponents/textFieldWidget2.dart';
import '../Components/widgetComponents/videoPopup.dart';

class sendMoneyScreen extends StatefulWidget {
  final double Balance;
  const sendMoneyScreen({super.key, required this.Balance});

  @override
  State<sendMoneyScreen> createState() => _sendMoneyScreenState();
}

class _sendMoneyScreenState extends State<sendMoneyScreen>
    with TickerProviderStateMixin {
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
    'Assets/Audio/sendmoneyhelp1.mp3',
    'Assets/Audio/sendmoneyhelp2.mp3',
    'Assets/Audio/sendmoneyhelp3.mp3',
  ];
  //Guide System
  void _startGuide() async {
    final hasValidAgentNumber = UserController.sendMoneyNum.text.length == 11;
    setState(() {
      _isGuidedMode = true;
      _currentStep = hasValidAgentNumber ? 1 : 0;
      if (hasValidAgentNumber) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context)
              .requestFocus(UserController.sendMoneyAmountFocus);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(UserController.sendMoneyNumFocus);
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
              .requestFocus(UserController.sendMoneyAmountFocus);
        });
      }
    });

    if (_currentStep < 3) {
      _playStepAudio(_currentStep);
    } else {
      _stopGuide();
    }
  }

  // Update _selectContact method
  Future<void> _selectContact() async {
    try {
      // Request contacts permission
      if (!await FlutterContacts.requestPermission()) {
        Get.snackbar('permissionRequired'.tr, 'contactsPermissionNeeded'.tr);
        return;
      }

      // Open native contact picker
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
        // Clean and validate number
        String cleanedNumber = phoneNumber
            .replaceAll(RegExp(r'[^\d]'), '') // Remove non-digits
            .replaceAll(RegExp(r'^0+'), '') // Remove leading zeros
            .replaceAll(' ', '');

        // Bangladeshi number validation
        if (cleanedNumber.startsWith('8801') && cleanedNumber.length == 13) {
          cleanedNumber = cleanedNumber.substring(2); // Remove country code
        } else if (cleanedNumber.startsWith('1') &&
            cleanedNumber.length == 10) {
          cleanedNumber = '0$cleanedNumber'; // Add missing leading zero
        }

        if (cleanedNumber.startsWith('01') && cleanedNumber.length == 11) {
          UserController.sendMoneyNum.text = cleanedNumber;
        } else {
          Get.snackbar('Invalid Number', 'Must be 11 digits starting with 01');
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to select contact: ${e.toString()}');
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
        style: TextStyle(
            fontSize: 14, color: Colors.red, fontStyle: FontStyle.italic),
        children: [
          TextSpan(
              text: 'importantNotes'.tr,
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: 'serviceAvailable'.tr),
          TextSpan(text: 'transactionFee'.tr),
          TextSpan(text: 'maxTransactions'.tr),
        ],
      ),
    );
  }

  bool _isDrawerOpen = false;
  late AudioPlayer _audioPlayer;
  bool _isAudioPlaying = false;
  @override
  void initState() {
    super.initState();
    _helpButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _audioPlayer = AudioPlayer();
    _initAudioSession();
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
    UserController.sendMoneyNumFocus.dispose();
    UserController.sendMoneyAmountFocus.dispose();
    _assistantTimer.cancel();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _helpButtonController.dispose();
    super.dispose();

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

  userController UserController = Get.put(userController());
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
        title: Text('sendMoney'.tr),
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
          // Your main content here
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                  SizedBox(height: 20),
                  Text(
                    'inputReceiverNumber'.tr,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
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
                              UserController.sendMoneyNum.text =
                                  value.substring(0, 11);
                            }
                          }
                        },
                        hintText: 'mobileNumber'.tr,
                        controller: UserController.sendMoneyNum,
                        inputType: TextInputType.number,
                        obscure: false,
                        iconPath: "Assets/Icons/login.svg",
                        focusNode: UserController.sendMoneyNumFocus,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isGuidedMode ? null : _selectContact,
                    child: Text(
                      'fromContacts'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10),
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
                        controller: UserController.sendMoneyAmount,
                        inputType: TextInputType.number,
                        obscure: false,
                        iconPath: "Assets/Icons/money2.svg",
                        focusNode: UserController.sendMoneyAmountFocus,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Text(
                    'availableBalance'.tr,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: const Color(0xFFEFE3C2),
                        borderRadius: BorderRadius.circular(12)),
                    width: 200,
                    height: 100,
                    child: Center(
                        child: Text(
                      "৳ ${widget.Balance.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 20),
                    )),
                  ),
                  const SizedBox(
                    height: 20,
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
                            onPressed: () async {
                              if (_isGuidedMode && _currentStep != 2) return;
                              // Make this async
                              final number = UserController.sendMoneyNum.text;
                              final amount =
                                  UserController.sendMoneyAmount.text;
                              if (_isGuidedMode && _currentStep != 2) return;

                              // Existing validations
                              if (number.isEmpty) {
                                Get.snackbar(
                                    'error'.tr, 'enterReceiverNumber'.tr,
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

                              if (parsedAmount > widget.Balance) {
                                Get.snackbar(
                                    'error'.tr, 'insufficientBalance'.tr,
                                    backgroundColor: Colors.red[200]);
                                return;
                              }

                              // New validations
                              try {
                                // Check if number belongs to current user
                                final currentUser =
                                    Supabase.instance.client.auth.currentUser;
                                if (currentUser == null) return;

                                final currentUserData = await Supabase
                                    .instance.client
                                    .from('users')
                                    .select('Number')
                                    .eq('userid', currentUser.id)
                                    .single();

                                if (number == currentUserData['Number']) {
                                  Get.snackbar(
                                      'error'.tr, 'sameAccountError'.tr,
                                      backgroundColor: Colors.red[200]);
                                  return;
                                }

                                // Check if receiver exists
                                final receiverExists = await Supabase
                                    .instance.client
                                    .from('users')
                                    .select()
                                    .eq('Number', number)
                                    .maybeSingle();

                                if (receiverExists == null) {
                                  Get.snackbar(
                                      'error'.tr, 'numberNotRegistered'.tr,
                                      backgroundColor: Colors.red[200]);
                                  return;
                                }

                                // Proceed to confirmation if all checks pass
                                Get.to(() => sendMoneyConfirm(
                                      Number: number,
                                      Amount: amount,
                                    ));
                                _stopGuide();
                                _assistantTimer.cancel();
                                _audioPlayer.stop();
                              } catch (e) {
                                Get.snackbar(
                                    'error'.tr, 'receiverVerificationFailed'.tr,
                                    backgroundColor: Colors.red[200]);
                              }
                            },
                            icon:
                                const Icon(Icons.arrow_circle_right, size: 80),
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
          ),

          // Right side drawer
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
                            .setAsset('Assets/Audio/sendMoney1.mp3');
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
                          videoAssetPath: 'Assets/Videos/SendMoney1.mp4',
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
                                      title: 'step1Title'.tr,
                                      text: 'step1Desc'.tr),
                                  const SizedBox(height: 15),
                                  _buildHelpSection(
                                      imagePath:
                                          'Assets/Images/sendMoneyHelp2.png',
                                      title: 'step2Title'.tr,
                                      text: 'step2Desc'.tr),
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
        ],
      ),
    );
  }
}
