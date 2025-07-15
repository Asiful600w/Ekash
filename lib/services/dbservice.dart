import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:thesis/Pages/HomePage/homepage.dart';
import 'package:thesis/Pages/LoginAndSignUp/loginPage.dart';
import 'package:thesis/controller/userController.dart';

class dbMethods {
  final SupabaseClient supabase = Supabase.instance.client;
//Signup Function
  Future<AuthResponse> signUp(
    String Email,
    String password,
  ) async {
    return await supabase.auth.signUp(password: password, email: Email);
  }

//SignIn Function
  Future<AuthResponse> login(String email, String password) async {
    return await supabase.auth
        .signInWithPassword(password: password, email: email);
  }

//Signout
  Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  //Update User Balance
  Future<void> updateBalance(double newBalance) async {
    try {
      await Supabase.instance.client
          .from('users')
          .update({'Balance': newBalance}).eq(
              'userid', Supabase.instance.client.auth.currentUser!.id);
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  //Insert transaction details into Transaction table
  Future<void> transactionInfoInsert(String transId, String type,
      String receiver, String sender, double amount, String senderId) async {
    await Supabase.instance.client.from('Transaction').insert({
      'transId': transId, // Link to auth user's UUID
      'created_at': DateTime.now().toIso8601String(),
      'type': type,
      'sender': sender,
      'receiver': receiver,
      'amount': amount,
      'senderflag': false,
      'sendersId': senderId
    });
  }

//Getting User Info as map
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('userid', userId)
          .single();

      return response as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      print('Supabase error: ${e.message}');
      return null;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  //Getting user id
  String? getCurrentuserId() {
    final session = supabase.auth.currentSession;
    final user = session?.user;
    return user?.id;
  }

  //Notification Methods
// Add to dbMethods class
}
