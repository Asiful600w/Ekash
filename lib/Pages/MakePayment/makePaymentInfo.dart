import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:thesis/Pages/HomePage/homepage.dart';

class makePaymentDetailPage extends StatefulWidget {
  final String transactionId;
  final String mobileNumber;
  final double rechargeAmount;
  final double currentBalance;

  makePaymentDetailPage({
    super.key,
    required this.transactionId,
    required this.mobileNumber,
    required this.rechargeAmount,
    required this.currentBalance,
  });

  @override
  State<makePaymentDetailPage> createState() => _makePaymentDetailPageState();
}

class _makePaymentDetailPageState extends State<makePaymentDetailPage> {
  late AudioPlayer _audioPlayer;
  late AnimationController _animationController;
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playSuccessSound();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('paymentSuccessful'.tr)),
        );
      }
    });
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.setAsset('Assets/Audio/payementconfirmhelp.mp3');
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('paymentDetails'.tr),
        backgroundColor: const Color(0xFFEFE3C2),
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFEFE3C2),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 3,
                blurRadius: 7,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'paymentSummary'.tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const Divider(thickness: 1, height: 20),
              _buildDetailRow('transactionID'.tr, widget.transactionId),
              _buildDetailRow('mobileNumber'.tr, widget.mobileNumber),
              _buildDetailRow('paymentAmount'.tr,
                  '৳${widget.rechargeAmount.toStringAsFixed(2)}'),
              _buildDetailRow('newBalance'.tr,
                  '৳${widget.currentBalance.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Get.offAll(sendMoney());
                      },
                      child: const Icon(
                        Icons.arrow_back_outlined,
                        color: Colors.black,
                      )),
                  Positioned(
                    left: -60,
                    child: Lottie.asset(
                      'Assets/LOTTIE/pointing.json',
                      width: 70,
                      height: 70,
                      repeat: true,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
