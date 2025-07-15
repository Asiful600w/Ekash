import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class balanceController extends GetxController {
  final supabase = Supabase.instance.client;
  final balance = 0.0.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBalance();
  }

  Future<void> fetchBalance() async {
    try {
      isLoading(true);
      errorMessage('');

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await supabase
          .from('users')
          .select('Balance')
          .eq('id', userId)
          .single();

      balance.value = (response['Balance'] as num).toDouble();
    } catch (e) {
      errorMessage('Error fetching balance: ${e.toString()}');
      Get.snackbar('Error', errorMessage.value);
    } finally {
      isLoading(false);
    }
  }

  Future<void> refreshBalance() async {
    await fetchBalance();
  }
}
