import 'package:flutter/material.dart';
import 'package:intl_phone_number_input_bonimo/intl_phone_number_input.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var darkTheme = ThemeData.dark().copyWith(primaryColor: Colors.blue);

    return MaterialApp(
      title: 'Demo',
      themeMode: ThemeMode.light,
      darkTheme: darkTheme,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Demo')),
        body: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController controller = TextEditingController();
  PhoneNumber number = PhoneNumber(isoCode: 'DE', dialCode: '+49');
  PhoneNumber initialNumber =
      PhoneNumber(phoneNumber: '123', isoCode: 'DE', dialCode: '+49');

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            InternationalPhoneNumberInput(
              onInputChanged: (PhoneNumber number) {
                print(number);
                if (this.number.phoneNumber != number.phoneNumber &&
                    this.number.dialCode != number.dialCode &&
                    this.number.isoCode != number.isoCode) {
                  setState(() {
                    this.number = number;
                  });
                }
              },
              onInputValidated: (bool value) {
                print(value);
                setState(
                  () {
                    // simulate real use case
                  },
                );
              },
              selectorConfig: SelectorConfig(
                selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                useBottomSheetSafeArea: true,
                setSelectorButtonAsPrefixIcon: true,
                padding: const EdgeInsets.only(
                    top: 4, bottom: 4, left: 12, right: 4),
                leadingPadding: 4,
                trailingSpace: false,
                borderRadius: 16,
              ),
              countries: ["DE", "AT"],
              cursorColor: Colors.red,
              iconColor: Colors.red,
              ignoreBlank: false,
              autoValidateMode: AutovalidateMode.onUserInteraction,
              selectorTextStyle: TextStyle(color: Colors.black),
              initialValue: initialNumber,
              textFieldController: controller,
              autoFocus: true,
              formatInput: false,
              keyboardType:
                  TextInputType.numberWithOptions(signed: true, decimal: true),
              inputDecoration: InputDecoration(
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(
                  color: Colors.red,
                )),
                hintText: 'Phone Number',
              ),
              // searchBoxDecoration: InputDecoration(
              //     border: const OutlineInputBorder(),
              //     focusedBorder: const OutlineInputBorder(
              //       borderSide: BorderSide(color: Colors.red),
              //     ),
              //     hintText: "test"),
              onSaved: (PhoneNumber number) {
                print('On Saved: $number');
              },
            ),
            ElevatedButton(
              onPressed: () {
                formKey.currentState?.validate();
              },
              child: Text('Validate'),
            ),
            ElevatedButton(
              onPressed: () {
                getPhoneNumber('+15417543010');
              },
              child: Text('Update'),
            ),
            ElevatedButton(
              onPressed: () {
                formKey.currentState?.save();
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void getPhoneNumber(String phoneNumber) async {
    PhoneNumber number =
        await PhoneNumber.getRegionInfoFromPhoneNumber(phoneNumber, 'US');
    print(number);
    setState(() {
      this.number = number;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
