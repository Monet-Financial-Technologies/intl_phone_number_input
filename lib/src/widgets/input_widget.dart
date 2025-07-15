import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input_bonimo/src/models/country_list.dart';
import 'package:intl_phone_number_input_bonimo/src/models/country_model.dart';
import 'package:intl_phone_number_input_bonimo/src/providers/country_provider.dart';
import 'package:intl_phone_number_input_bonimo/src/utils/formatter/as_you_type_formatter.dart';
import 'package:intl_phone_number_input_bonimo/src/utils/phone_number.dart';
import 'package:intl_phone_number_input_bonimo/src/utils/phone_number/phone_number_util.dart';
import 'package:intl_phone_number_input_bonimo/src/utils/selector_config.dart';
import 'package:intl_phone_number_input_bonimo/src/utils/test/test_helper.dart';
import 'package:intl_phone_number_input_bonimo/src/utils/util.dart';
import 'package:intl_phone_number_input_bonimo/src/utils/widget_view.dart';
import 'package:intl_phone_number_input_bonimo/src/widgets/selector_button.dart';

/// Enum for [SelectorButton] types.
///
/// Available type includes:
///   * [PhoneInputSelectorType.DROPDOWN]
///   * [PhoneInputSelectorType.BOTTOM_SHEET]
///   * [PhoneInputSelectorType.DIALOG]
enum PhoneInputSelectorType { DROPDOWN, BOTTOM_SHEET, DIALOG }

/// A [TextFormField] for [InternationalPhoneNumberInput].
///
/// [initialValue] accepts a [PhoneNumber] this is used to set initial values
/// for phone the input field and the selector button
///
/// [selectorButtonOnErrorPadding] is a double which is used to align the selector
/// button with the input field when an error occurs
///
/// [locale] accepts a country locale which will be used to translation, if the
/// translation exist
///
/// [countries] accepts list of string on Country isoCode, if specified filters
/// available countries to match the [countries] specified.
class InternationalPhoneNumberInput extends StatefulWidget {
  final SelectorConfig selectorConfig;

  final ValueChanged<PhoneNumber>? onInputChanged;
  final ValueChanged<bool>? onInputValidated;

  final VoidCallback? onSubmit;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final ValueChanged<PhoneNumber>? onSaved;

  final Key? fieldKey;
  final TextEditingController? textFieldController;
  final TextInputType keyboardType;
  final TextInputAction? keyboardAction;

  final PhoneNumber? initialValue;
  final String? hintText;
  final String? errorMessage;

  final double selectorButtonOnErrorPadding;

  /// Ignored if [setSelectorButtonAsPrefixIcon = true]
  final double spaceBetweenSelectorAndTextField;
  final int maxLength;

  final bool isEnabled;
  final bool formatInput;
  final bool autoFocus;
  final bool autoFocusSearch;
  final AutovalidateMode autoValidateMode;
  final bool ignoreBlank;
  final bool countrySelectorScrollControlled;

  final String? locale;

  final TextStyle? textStyle;
  final TextStyle? selectorTextStyle;
  final InputBorder? inputBorder;
  final InputDecoration? inputDecoration;
  final InputDecoration? searchBoxDecoration;
  final Color? cursorColor;
  final Color? iconColor;
  final TextAlign textAlign;
  final TextAlignVertical textAlignVertical;
  final EdgeInsets scrollPadding;

  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;

  final List<String>? countries;

  InternationalPhoneNumberInput(
      {Key? key,
      this.selectorConfig = const SelectorConfig(),
      required this.onInputChanged,
      this.onInputValidated,
      this.onSubmit,
      this.onFieldSubmitted,
      this.validator,
      this.onSaved,
      this.fieldKey,
      this.textFieldController,
      this.keyboardAction,
      this.keyboardType = TextInputType.phone,
      this.initialValue,
      this.hintText = 'Phone number',
      this.errorMessage = 'Invalid phone number',
      this.selectorButtonOnErrorPadding = 24,
      this.spaceBetweenSelectorAndTextField = 12,
      this.maxLength = 15,
      this.isEnabled = true,
      this.formatInput = true,
      this.autoFocus = false,
      this.autoFocusSearch = false,
      this.autoValidateMode = AutovalidateMode.disabled,
      this.ignoreBlank = false,
      this.countrySelectorScrollControlled = true,
      this.locale,
      this.textStyle,
      this.selectorTextStyle,
      this.inputBorder,
      this.inputDecoration,
      this.searchBoxDecoration,
      this.textAlign = TextAlign.start,
      this.textAlignVertical = TextAlignVertical.center,
      this.scrollPadding = const EdgeInsets.all(20.0),
      this.focusNode,
      this.cursorColor,
      this.iconColor,
      this.autofillHints,
      this.countries})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InternationalPhoneNumberInput> {
  TextEditingController? controller;
  double selectorButtonBottomPadding = 0;

  Country? country;
  List<Country> countries = [];
  bool isNotValid = true;
  List<TextInputFormatter> formatters = [];

  @override
  void initState() {
    super.initState();
    loadCountries();
    controller = widget.textFieldController ?? TextEditingController();
    initialiseWidget();
  }

  @override
  void setState(fn) {
    if (this.mounted) {
      super.setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InputWidgetView(
      state: this,
    );
  }

  @override
  void didUpdateWidget(InternationalPhoneNumberInput oldWidget) {
    loadCountries(previouslySelectedCountry: country);
    if (oldWidget.initialValue?.hash != widget.initialValue?.hash) {
      if (country!.alpha2Code != widget.initialValue?.isoCode) {
        loadCountries();
      }
      initialiseWidget();
    }
    super.didUpdateWidget(oldWidget);
  }

  /// [initialiseWidget] sets initial values of the widget
  void initialiseWidget() async {
    if (widget.initialValue != null) {
      if (widget.initialValue!.isoCode != null) {
        final country = Utils.getCountryFromIsoCode(
            countries, widget.initialValue!.isoCode!);
        final number = (country?.dialCode?.substring(1) ?? '') +
            (widget.initialValue!.phoneNumber ?? '');
        controller!.value = _formatControllerValue(
          TextEditingValue.empty,
          TextEditingValue(text: number),
        );
      }

      phoneNumberControllerListener();
    }
  }

  /// loads countries from [Countries.countryList] and selected Country
  void loadCountries({Country? previouslySelectedCountry}) {
    if (this.mounted) {
      List<Country> countries =
          CountryProvider.getCountriesData(countries: widget.countries);

      Country? country = previouslySelectedCountry ??
          Utils.getInitialSelectedCountry(
            countries,
            widget.initialValue?.isoCode ?? '',
          );

      // Remove potential duplicates
      countries = countries.toSet().toList();

      final CountryComparator? countryComparator =
          widget.selectorConfig.countryComparator;
      if (countryComparator != null) {
        countries.sort(countryComparator);
      }

      setState(() {
        this.countries = countries;
        this.country = country;
        this.formatters = [
          FilteringTextInputFormatter.digitsOnly,
          IsoCodeFormatter(countries: countries)
        ];
      });
    }
  }

  /// Listener that validates changes from the widget, returns a bool to
  /// the `ValueCallback` [widget.onInputValidated]
  void phoneNumberControllerListener() {
    if (this.mounted) {
      String parsedPhoneNumberString =
          controller!.text.replaceAll(RegExp(r'[^\d+]'), '');

      Country? countryFromString =
          Utils.getCountryFromNumber(countries, parsedPhoneNumberString);
      if (this.country != countryFromString) {
        setState(() {
          this.country = countryFromString;
        });
      }

      // Library expects phoneNumber to be without isoCode
      String phoneNumberWithoutIso = countryFromString == null
          ? ''
          : parsedPhoneNumberString
              .substring(countryFromString.dialCode!.length - 1);

      getParsedPhoneNumber(phoneNumberWithoutIso, this.country?.alpha2Code)
          .then((phoneNumber) {
        if (phoneNumber == null) {
          String phoneNumber =
              '${this.country?.dialCode}$phoneNumberWithoutIso';

          if (widget.onInputChanged != null) {
            widget.onInputChanged!(PhoneNumber(
                phoneNumber: phoneNumber,
                isoCode: this.country?.alpha2Code,
                dialCode: this.country?.dialCode));
          }

          if (widget.onInputValidated != null) {
            widget.onInputValidated!(false);
          }
          this.isNotValid = true;
        } else {
          if (widget.onInputChanged != null) {
            widget.onInputChanged!(PhoneNumber(
                phoneNumber: phoneNumber,
                isoCode: this.country?.alpha2Code,
                dialCode: this.country?.dialCode));
          }

          if (widget.onInputValidated != null) {
            widget.onInputValidated!(true);
          }
          this.isNotValid = false;
        }
      });
    }
  }

  /// Returns a formatted String of [phoneNumber] with [isoCode], returns `null`
  /// if [phoneNumber] is not valid or if an [Exception] is caught.
  Future<String?> getParsedPhoneNumber(
      String phoneNumber, String? isoCode) async {
    if (phoneNumber.isNotEmpty && isoCode != null) {
      try {
        bool? isValidPhoneNumber = await PhoneNumberUtil.isValidNumber(
            phoneNumber: phoneNumber, isoCode: isoCode);

        if (isValidPhoneNumber!) {
          return await PhoneNumberUtil.normalizePhoneNumber(
              phoneNumber: phoneNumber, isoCode: isoCode);
        }
      } on Exception {
        return null;
      }
    }
    return null;
  }

  /// Creates or Select [InputDecoration]
  InputDecoration getInputDecoration(InputDecoration? decoration) {
    InputDecoration value = decoration ??
        InputDecoration(
          border: widget.inputBorder ?? UnderlineInputBorder(),
          hintText: widget.hintText,
        );

    if (widget.selectorConfig.setSelectorButtonAsPrefixIcon) {
      return value.copyWith(
          prefixIcon: SelectorButton(
        country: country,
        countries: countries,
        onCountryChanged: onCountryChanged,
        selectorConfig: widget.selectorConfig,
        selectorTextStyle: widget.selectorTextStyle,
        searchBoxDecoration: widget.searchBoxDecoration,
        cursorColor: widget.cursorColor,
        locale: locale,
        isEnabled: widget.isEnabled,
        autoFocusSearchField: widget.autoFocusSearch,
        isScrollControlled: widget.countrySelectorScrollControlled,
        iconColor: widget.iconColor,
      ));
    }

    return value;
  }

  /// Validate the phone number when a change occurs
  void onChanged(String value) {
    phoneNumberControllerListener();
  }

  /// Validate and returns a validation error when [FormState] validate is called.
  ///
  /// Also updates [selectorButtonBottomPadding]
  String? validator(String? value) {
    bool isValid =
        this.isNotValid && (value!.isNotEmpty || widget.ignoreBlank == false);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (isValid && widget.errorMessage != null) {
        setState(() {
          this.selectorButtonBottomPadding =
              widget.selectorButtonOnErrorPadding;
        });
      } else {
        setState(() {
          this.selectorButtonBottomPadding = 0;
        });
      }
    });

    return isValid ? widget.errorMessage : null;
  }

  TextEditingValue _formatControllerValue(
      TextEditingValue oldValue, TextEditingValue newValue) {
    for (final f in formatters) {
      newValue = f.formatEditUpdate(oldValue, newValue);
    }
    return newValue;
  }

  /// Changes Selector Button Country and Validate Change.
  void onCountryChanged(Country? country) {
    setState(() {
      final oldValue = controller!.value;

      // Replace text's isoCode
      if (this.country != null) {
        controller!.text =
            controller!.text.substring(this.country!.dialCode!.length - 1);
      }
      if (country != null) {
        controller!.text = controller!.text =
            country.dialCode!.substring(1) + controller!.text;
      }

      final newValue = controller!.value;

      controller!.value = _formatControllerValue(oldValue, newValue);

      // For some reason selects whole number when setting text, so
      // use PostFrameCallback to force collapsed text selection
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller!.selection = TextSelection.collapsed(
          offset: controller!.text.length,
        );
      });

      this.country = country;
    });
    phoneNumberControllerListener();
  }

  void _phoneNumberSaved() {
    if (this.mounted) {
      String parsedPhoneNumberString =
          controller!.text.replaceAll(RegExp(r'[^\d+]'), '');

      String phoneNumber =
          '${this.country?.dialCode ?? ''}' + parsedPhoneNumberString;

      widget.onSaved?.call(
        PhoneNumber(
            phoneNumber: phoneNumber,
            isoCode: this.country?.alpha2Code,
            dialCode: this.country?.dialCode),
      );
    }
  }

  /// Saved the phone number when form is saved
  void onSaved(String? value) {
    _phoneNumberSaved();
  }

  /// Corrects duplicate locale
  String? get locale {
    if (widget.locale == null) return null;

    if (widget.locale!.toLowerCase() == 'nb' ||
        widget.locale!.toLowerCase() == 'nn') {
      return 'no';
    }
    return widget.locale;
  }
}

class _InputWidgetView
    extends WidgetView<InternationalPhoneNumberInput, _InputWidgetState> {
  final _InputWidgetState state;

  _InputWidgetView({Key? key, required this.state})
      : super(key: key, state: state);

  @override
  Widget build(BuildContext context) {
    final countryCode = state.country?.alpha2Code ?? '';
    final dialCode = state.country?.dialCode ?? '';

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (!widget.selectorConfig.setSelectorButtonAsPrefixIcon) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SelectorButton(
                  country: state.country,
                  countries: state.countries,
                  onCountryChanged: state.onCountryChanged,
                  selectorConfig: widget.selectorConfig,
                  selectorTextStyle: widget.selectorTextStyle,
                  searchBoxDecoration: widget.searchBoxDecoration,
                  locale: state.locale,
                  isEnabled: widget.isEnabled,
                  autoFocusSearchField: widget.autoFocusSearch,
                  isScrollControlled: widget.countrySelectorScrollControlled,
                  cursorColor: widget.cursorColor,
                  iconColor: widget.iconColor,
                ),
                SizedBox(
                  height: state.selectorButtonBottomPadding,
                ),
              ],
            ),
            SizedBox(width: widget.spaceBetweenSelectorAndTextField),
          ],
          Flexible(
            child: TextFormField(
              key: widget.fieldKey ?? Key(TestHelper.TextInputKeyValue),
              textDirection: TextDirection.ltr,
              controller: state.controller,
              cursorColor: widget.cursorColor,
              focusNode: widget.focusNode,
              enabled: widget.isEnabled,
              autofocus: widget.autoFocus,
              keyboardType: widget.keyboardType,
              textInputAction: widget.keyboardAction,
              style: widget.textStyle,
              decoration: state.getInputDecoration(widget.inputDecoration),
              textAlign: widget.textAlign,
              textAlignVertical: widget.textAlignVertical,
              onEditingComplete: widget.onSubmit,
              onFieldSubmitted: widget.onFieldSubmitted,
              autovalidateMode: widget.autoValidateMode,
              autofillHints: widget.autofillHints,
              validator: widget.validator ?? state.validator,
              onSaved: state.onSaved,
              scrollPadding: widget.scrollPadding,
              inputFormatters: state.formatters,
              onChanged: state.onChanged,
            ),
          )
        ],
      ),
    );
  }
}

class IsoCodeFormatter extends TextInputFormatter {
  List<Country> countries;

  IsoCodeFormatter({required this.countries});

  (bool, TextEditingValue) _doFormatting(
      bool wasSelection,
      TextEditingValue oldValue,
      bool isSelection,
      TextEditingValue newValue,
      Country? country) {
    bool needsReevaluation = false;

    final String noSpaceText = newValue.text.replaceAll(' ', '');
    if (country == null) {
      return (
        needsReevaluation,
        newValue.copyWith(
          text: noSpaceText,
          // Brings cursor back if user presses space with no valid country
          selection: isSelection
              ? newValue.selection
              : TextSelection.collapsed(
                  offset: min(newValue.selection.start, noSpaceText.length)),
        )
      );
    } else {
      final String isoCode = country.dialCode!.substring(1);

      // Ensure space after isoCode
      String formattedValue = noSpaceText.length >= isoCode.length
          ? '${noSpaceText.substring(0, isoCode.length)} ${noSpaceText.substring(isoCode.length)}'
          : noSpaceText;

      final bool spaceAdded = newValue.text.length <= isoCode.length ||
          (newValue.text.length > isoCode.length &&
              newValue.text[isoCode.length] != ' ');

      // Extra spaces removed
      final int spacesRemoved =
          max(newValue.text.length - formattedValue.length, 0);

      // Push cursor by 1 if space is added, IF selection is after it
      int spaceOffset =
          spaceAdded && newValue.selection.start >= isoCode.length ? 1 : 0;
      spaceOffset -= spacesRemoved;

      // Get first letter difference (check for space deletion)
      int i = 0;
      String? firstDiff;
      while (i < oldValue.text.length && i < newValue.text.length) {
        if (oldValue.text[i] != newValue.text[i]) {
          firstDiff = oldValue.text[i];
          break;
        }
        i++;
      }
      if (firstDiff == null && oldValue.text.length != newValue.text.length) {
        firstDiff = oldValue.text.length > newValue.text.length
            ? oldValue.text[newValue.text.length]
            : newValue.text[oldValue.text.length];
      }

      // Case for removal of space in front of isoCode by user with
      // backspace and not selection (delete this space + move cursor back)
      if (!wasSelection &&
          // Had space before
          (oldValue.text.length > isoCode.length &&
              oldValue.text[isoCode.length] == ' ') &&
          // If last text was 1 char longer than this text (ensure deletion)
          (oldValue.text.length - 1 == newValue.text.length) &&
          // And doesn't anymore (space removed)
          firstDiff == ' ') {
        needsReevaluation = true;
        formattedValue = formattedValue.substring(0, isoCode.length - 1) +
            formattedValue.substring(isoCode.length);

        spaceOffset -= 2;
      }

      return (
        needsReevaluation,
        newValue.copyWith(
          text: formattedValue,
          selection: isSelection
              ? newValue.selection
              : TextSelection.collapsed(
                  offset: min(newValue.selection.start + spaceOffset,
                      formattedValue.length)),
        )
      );
    }
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    bool reevaluate = true;
    while (reevaluate) {
      Country? newCountry =
          Utils.getCountryFromNumber(countries, newValue.text);

      final (bool needsReevaluation, TextEditingValue formattedText) =
          _doFormatting(
        oldValue.selection.start != oldValue.selection.end,
        oldValue,
        newValue.selection.start != newValue.selection.end,
        newValue,
        newCountry,
      );
      reevaluate = needsReevaluation;
      newValue = formattedText;
    }
    return newValue;
  }
}
