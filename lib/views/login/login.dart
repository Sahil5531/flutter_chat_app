import 'package:demochat/libraries/custom_image.dart';
import 'package:flutter/material.dart';
import 'package:demochat/components/custom_alert.dart';
import 'package:demochat/libraries/singleton.dart';
import 'package:demochat/components/my_button.dart';
import 'package:demochat/views/otp/otp.dart';
import 'package:demochat/libraries/custom_classes.dart';
import 'package:demochat/web_api/api_call.dart';
import '../../constants/global_functions.dart';
import '../../libraries/custom_widgets.dart';
import '../../components/custom_text_field.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  // Text edit controller
  final numberController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Singleton.instance.context = context;
    return loader(
      Scaffold(
        appBar: appBar('Login'),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(left: 40, right: 40, bottom: 20),
              child: Center(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 50,
                    ),
                    // Logo Image
                    Image.asset(
                      ImagePath.instance.logoImage,
                      scale: 3,
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    // Text
                    const Text("Enter your phone number to continue.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 17.0, fontWeight: FontWeight.bold)),
                    const SizedBox(
                      height: 30,
                    ),
                    // Text Field Phone Number
                    phoneNumberTextField(),
                    const SizedBox(
                      height: 50,
                    ),
                    // Login button
                    buttonLogin()
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Text Field
  Widget phoneNumberTextField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: cornerRadiusTen(),
            boxShadow: shadowTextField(),
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 12),
            child: Row(
              children: [
                getImage(ImagePath.instance.flagIndia, 20, 25),
                const SizedBox(width: 2),
                const Text(
                  '+91',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomTextField(
            textController: numberController,
            hintText: 'Phone Number',
            obscureText: false,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }

  // Button
  Widget buttonLogin() {
    return MyButtons(
      title: "Login",
      onTap: () {
        // Send OTP API.
        sendOtp();
      },
      height: 45,
    );
  }

// API's
  Future sendOtp() async {
    if (numberController.text.isEmpty) {
      showAlertOk('Error', 'Please enter phone number');
      return;
    }
    final number = "+91${numberController.text}";
    if (!isValidPhoneNumber(number) || number.length != 13) {
      showAlertOk('Error', 'Please enter valid phone number');
      return;
    }
    APICall.instance.sendOtpAPI(context, number, callBack: (data) {
      final otp = data['otp'];
      showAlertOk('Otp', 'Here is your OTP: ${otp.toString()}', callBack: () {
        Navigator.push(
            Singleton.instance.context,
            MaterialPageRoute(
                builder: (context) => OtpVc(
                      number: number,
                      receivedOtp: otp.toString(),
                    )));
      });
    });
  }
}
