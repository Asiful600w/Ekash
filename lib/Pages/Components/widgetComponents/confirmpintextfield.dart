import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinTextField extends StatefulWidget {
  final Function(int index, String value)? onChanged;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final Function(String)? onPinEntered;
  final int pinLength;
  final double fieldHeight;
  final double fieldWidth;
  final TextStyle textStyle;
  const PinTextField(
      {super.key,
      required this.controllers,
      required this.focusNodes,
      this.onPinEntered,
      this.pinLength = 5,
      required this.fieldHeight,
      required this.fieldWidth,
      required this.textStyle,
      this.onChanged});

  @override
  State<PinTextField> createState() => _PinTextFieldState();
}

class _PinTextFieldState extends State<PinTextField> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final availableWidth = constraints.maxWidth;
      final totalMargin = widget.pinLength * 4; // Total space between boxes
      final itemWidth = (availableWidth - totalMargin) / widget.pinLength;

      (availableWidth - (widget.pinLength - 1) * 4) / widget.pinLength;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(widget.pinLength, (index) {
          return Container(
            width: widget.fieldWidth,
            height: widget.fieldHeight,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            child: TextField(
              controller: widget.controllers[index],
              focusNode: widget.focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              textInputAction: TextInputAction.done,
              enableInteractiveSelection: false,
              obscureText: true,
              obscuringCharacter: '•',
              style: widget.textStyle,
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  counterText: '',
                  isDense: true),
              onChanged: (value) {
                if (value.length == 1) {
                  if (index < widget.pinLength - 1) {
                    // Changed from 3 to 4 for 5-digit PIN
                    FocusScope.of(context)
                        .requestFocus(widget.focusNodes[index + 1]);
                  } else {
                    widget.focusNodes[index].unfocus();
                    // Submit PIN or handle completion
                    final pin = widget.controllers.map((c) => c.text).join();
                    widget.onPinEntered?.call(pin);
                  }
                } else if (value.isEmpty) {
                  if (index > 0) {
                    FocusScope.of(context)
                        .requestFocus(widget.focusNodes[index - 1]);
                  }
                }
                widget.onChanged?.call(index, value);
              },
            ),
          );
        }),
      );
    });
  }
}
