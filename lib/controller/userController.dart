import 'package:flutter/material.dart';
import 'package:get/get.dart';

class userController extends GetxController {
  TextEditingController number = TextEditingController();
  TextEditingController pin = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController name = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController emailSign = TextEditingController();
  TextEditingController passSign = TextEditingController();
  TextEditingController sendMoneyNum = TextEditingController();
  TextEditingController sendMoneyAmount = TextEditingController();
  TextEditingController rechargeNum = TextEditingController();
  TextEditingController rechargeAmount = TextEditingController();
  TextEditingController paymentNum = TextEditingController();
  TextEditingController paymentAmount = TextEditingController();
  TextEditingController cashOutNum = TextEditingController();
  TextEditingController cashOutAmount = TextEditingController();
  FocusNode sendMoneyNumFocus = FocusNode();
  FocusNode sendMoneyAmountFocus = FocusNode();
  FocusNode rechargeNumFocus = FocusNode();
  FocusNode rechargeAmountFocus = FocusNode();
  FocusNode paymentNumFocus = FocusNode();
  FocusNode paymentAmountFocus = FocusNode();
  FocusNode cashOutNumFocus = FocusNode();
  FocusNode cashOutAmountFocus = FocusNode();
}
