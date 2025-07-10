import 'package:flutter/material.dart';
import 'package:intl_phone_number_input_bonimo/src/models/country_model.dart';
import 'package:intl_phone_number_input_bonimo/src/utils/test/test_helper.dart';
import 'package:intl_phone_number_input_bonimo/src/utils/util.dart';

/// Creates a list of Countries with a search textfield.
class CountrySearchListWidget extends StatefulWidget {
  final List<Country> countries;
  final InputDecoration? searchBoxDecoration;
  final String? locale;
  final ScrollController? scrollController;
  final bool autoFocus;
  final bool? showFlags;
  final bool? useEmoji;
  final bool? useCircleAvatar;
  final Color? cursorColor;

  CountrySearchListWidget(
    this.countries,
    this.locale, {
    this.searchBoxDecoration,
    this.scrollController,
    this.showFlags,
    this.useEmoji,
    this.useCircleAvatar,
    this.cursorColor,
    this.autoFocus = false,
  });

  @override
  _CountrySearchListWidgetState createState() =>
      _CountrySearchListWidgetState();
}

class _CountrySearchListWidgetState extends State<CountrySearchListWidget> {
  late TextEditingController _searchController = TextEditingController();
  late List<Country> filteredCountries;

  @override
  void initState() {
    final String value = _searchController.text.trim();
    filteredCountries = Utils.filterCountries(
      countries: widget.countries,
      locale: widget.locale,
      value: value,
    );
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Returns [InputDecoration] of the search box
  InputDecoration getSearchBoxDecoration() {
    return widget.searchBoxDecoration ??
        InputDecoration(labelText: 'Search by country name or dial code');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextFormField(
            key: Key(TestHelper.CountrySearchInputKeyValue),
            decoration: getSearchBoxDecoration(),
            cursorColor: widget.cursorColor,
            controller: _searchController,
            autofocus: widget.autoFocus,
            onChanged: (value) {
              final String value = _searchController.text.trim();
              return setState(
                () => filteredCountries = Utils.filterCountries(
                  countries: widget.countries,
                  locale: widget.locale,
                  value: value,
                ),
              );
            },
          ),
        ),
        Flexible(
          child: ListView.builder(
            controller: widget.scrollController,
            shrinkWrap: true,
            itemCount: filteredCountries.length,
            itemBuilder: (BuildContext context, int index) {
              Country country = filteredCountries[index];

              return DirectionalCountryListTile(
                country: country,
                locale: widget.locale,
                showFlags: widget.showFlags!,
                useEmoji: widget.useEmoji!,
                useCircleAvatar: widget.useCircleAvatar!,
              );
              // return ListTile(
              //   key: Key(TestHelper.countryItemKeyValue(country.alpha2Code)),
              //   leading: widget.showFlags!
              //       ? _Flag(country: country, useEmoji: widget.useEmoji)
              //       : null,
              //   title: Align(
              //     alignment: AlignmentDirectional.centerStart,
              //     child: Text(
              //       '${Utils.getCountryName(country, widget.locale)}',
              //       textDirection: Directionality.of(context),
              //       textAlign: TextAlign.start,
              //     ),
              //   ),
              //   subtitle: Align(
              //     alignment: AlignmentDirectional.centerStart,
              //     child: Text(
              //       '${country.dialCode ?? ''}',
              //       textDirection: TextDirection.ltr,
              //       textAlign: TextAlign.start,
              //     ),
              //   ),
              //   onTap: () => Navigator.of(context).pop(country),
              // );
            },
          ),
        ),
      ],
    );
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}

class DirectionalCountryListTile extends StatelessWidget {
  final Country country;
  final String? locale;
  final bool showFlags;
  final bool useEmoji;
  final bool useCircleAvatar;

  const DirectionalCountryListTile(
      {Key? key,
      required this.country,
      required this.locale,
      required this.showFlags,
      required this.useEmoji,
      required this.useCircleAvatar})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
        key: Key(country.alpha2Code!),
        onPressed: () {
          Navigator.of(context).pop(country);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              if (showFlags)
                _Flag(
                    country: country,
                    useEmoji: useEmoji,
                    useCircleAvatar: useCircleAvatar),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${Utils.getCountryName(country, locale)}',
                      textDirection: Directionality.of(context),
                      textAlign: TextAlign.start,
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      '${country.dialCode ?? ''}',
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.start,
                    ),
                  ),
                ],
              )
            ],
          ),
        ));

    return Padding(
        padding: const EdgeInsets.all(16),
        child: ListTile(
          key: Key(TestHelper.countryItemKeyValue(country.alpha2Code)),
          leading: (showFlags
              ? _Flag(
                  country: country,
                  useEmoji: useEmoji,
                  useCircleAvatar: useCircleAvatar)
              : null),
          title: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${Utils.getCountryName(country, locale)}',
              textDirection: Directionality.of(context),
              textAlign: TextAlign.start,
            ),
          ),
          subtitle: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${country.dialCode ?? ''}',
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
            ),
          ),
          onTap: () => Navigator.of(context).pop(country),
        ));
  }
}

class _Flag extends StatelessWidget {
  final Country? country;
  final bool? useEmoji;
  final bool useCircleAvatar;

  const _Flag(
      {Key? key, this.country, this.useEmoji, required this.useCircleAvatar})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return country != null
        ? Container(
            child: useEmoji!
                ? Text(
                    Utils.generateFlagEmojiUnicode(country?.alpha2Code ?? ''),
                    style: Theme.of(context).textTheme.headlineSmall,
                  )
                : country?.flagUri != null
                    ? useCircleAvatar
                        ? CircleAvatar(
                            backgroundImage: AssetImage(
                              country!.flagUri,
                              package: 'intl_phone_number_input_bonimo',
                            ),
                          )
                        : SizedBox(
                            width: 28,
                            height: 28,
                            child: FittedBox(
                              child: Image.asset(
                                country!.flagUri,
                                package: 'intl_phone_number_input_bonimo',
                              ),
                            ),
                          )
                    : SizedBox.shrink(),
          )
        : SizedBox.shrink();
  }
}
