import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lottie/lottie.dart';
import 'package:thesis/Pages/HomePage/homepage.dart';

class TransactionDetailPage extends StatefulWidget {
  final String transactionId;
  final String receiverNumber;
  final double sendingAmount;
  final double currentBalance;

  const TransactionDetailPage({
    super.key,
    required this.transactionId,
    required this.receiverNumber,
    required this.sendingAmount,
    required this.currentBalance,
  });

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
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
          SnackBar(content: Text('transactionSuccessful'.tr)),
        );
      }
    });
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.setAsset('Assets/Audio/sendmoneyconfirmhelp.mp3');
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
        title: const Text('Transaction Details'),
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
                'transactionSummary'.tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const Divider(thickness: 1, height: 20),
              _buildDetailRow('transactionID'.tr, widget.transactionId),
              _buildDetailRow('receiverNumber'.tr, widget.receiverNumber),
              _buildDetailRow('sendingAmount'.tr,
                  '৳${widget.sendingAmount.toStringAsFixed(2)}'),
              _buildDetailRow('newBalance'.tr,
                  '৳${widget.currentBalance.toStringAsFixed(2)}'),
              const SizedBox(height: 20),
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
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
