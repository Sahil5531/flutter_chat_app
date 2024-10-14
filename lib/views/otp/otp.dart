import 'package:flutter/material.dart';
import 'package:demochat/components/custom_alert.dart';
import 'package:demochat/components/my_button.dart';
import 'package:demochat/components/otp_text_field.dart';
import 'package:demochat/libraries/custom_widgets.dart';
import 'package:demochat/views/home/home.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/web_api/api_call.dart';
import '../../components/flat_button.dart';

class OtpVc extends StatefulWidget {
  const OtpVc({super.key, required this.number, required this.receivedOtp});
  final String number;
  final String receivedOtp;
  @override
  State<OtpVc> createState() => _OtpVcState();
}

class _OtpVcState extends State<OtpVc> {
  List<TextEditingController> textEditingControllerList = [];
  final textFieldOneEditController = TextEditingController();
  final textFieldTwoEditController = TextEditingController();
  final textFieldThreeEditController = TextEditingController();
  final textFieldFourEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    textEditingControllerList = [
      textFieldOneEditController,
      textFieldTwoEditController,
      textFieldThreeEditController,
      textFieldFourEditController
    ];
  }

  @override
  Widget build(BuildContext context) {
    return loader(
      Scaffold(
        appBar: appBar('OTP'),
        body: SafeArea(
          child: SingleChildScrollView(
              child: Padding(
            padding: const EdgeInsets.only(left: 40, right: 40, bottom: 20),
            child: Center(
              child: Column(
                children: [
                  const SizedBox(
                    height: 50.0,
                  ),
                  Image.asset(
                    ImagePath.instance.logoImage,
                    scale: 3,
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  const Text(
                    "Enter the OTP received on your phone number",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 30.0,
                  ),
                  otpFields(),
                  const SizedBox(
                    height: 50.0,
                  ),
                  buttonVerify(),
                  const SizedBox(
                    height: 20,
                  ),
                  resendOtpTextButton(),
                ],
              ),
            ),
          )),
        ),
      ),
    );
  }

  // OTP Fields
  Widget otpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < textEditingControllerList.length; i++)
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: OtpTextField(
              controller: textEditingControllerList[i],
              onChanged: () {
                if (i == 0 && textEditingControllerList[i].text == '') {
                  FocusScope.of(context).previousFocus();
                } else {
                  FocusScope.of(context).nextFocus();
                }
              },
              focus: i == 0,
            ),
          ),
      ],
    );
  }

  // Button
  Widget buttonVerify() {
    return MyButtons(
      title: "Verify",
      onTap: () {
        // Verify OTP API.
        verifyOtp();
      },
      backgroundColor: null,
      height: 45,
      width: null,
    );
  }

  // Resend OTP
  Widget resendOtpTextButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 3.0),
          child: Text(
            "Didn't received OTP?",
            style: TextStyle(fontSize: 12.0),
          ),
        ),
        const SizedBox(
          width: 2,
        ),
        CustomTextButton(
          title: "Resend OTP",
          fontSize: 15.0,
          fontWeight: FontWeight.bold,
          textColor: Colors.blueAccent,
          onTap: () {
            // Resend OTP API.
            resendOtp();
          },
        )
      ],
    );
  }

  // Clear OTP Fields
  Future clearOtpFields() async {
    for (int i = 0; i < textEditingControllerList.length; i++) {
      textEditingControllerList[i].clear();
    }
  }

  // API's
  Future verifyOtp() async {
    final otp = textFieldOneEditController.text +
        textFieldTwoEditController.text +
        textFieldThreeEditController.text +
        textFieldFourEditController.text;
    APICall.instance.verifyOtpAPI(context, number: widget.number, otp: otp,
        callBack: (response) {
      if (response) {
        Navigator.push(
            context, MaterialPageRoute(builder: ((context) => const HomeVc())));
      } else {
        showAlertOk("Alert", "Otp doest not matched.");
      }
    });
  }

  Future resendOtp() async {
    APICall.instance.sendOtpAPI(context, widget.number, callBack: (data) {
      clearOtpFields();
      final otp = data['otp'];
      showAlertOk('Otp', 'Here is your OTP: ${otp.toString()}');
    });
  }
}
