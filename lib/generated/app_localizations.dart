import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don’t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'User Name'**
  String get username;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @middleName.
  ///
  /// In en, this message translates to:
  /// **'Middle Name'**
  String get middleName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get alreadyHaveAccount;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @enterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get enterOtp;

  /// No description provided for @codeSentTo.
  ///
  /// In en, this message translates to:
  /// **'We’ve sent a code to'**
  String get codeSentTo;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in'**
  String get resendIn;

  /// No description provided for @service_driver.
  ///
  /// In en, this message translates to:
  /// **'Private Driver'**
  String get service_driver;

  /// No description provided for @service_full_time_maid.
  ///
  /// In en, this message translates to:
  /// **'Full-time Maid'**
  String get service_full_time_maid;

  /// No description provided for @service_maid_4h.
  ///
  /// In en, this message translates to:
  /// **'Maid for 4 hours'**
  String get service_maid_4h;

  /// No description provided for @service_maid_8h.
  ///
  /// In en, this message translates to:
  /// **'Maid for 8 hours'**
  String get service_maid_8h;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'home'**
  String get home;

  /// No description provided for @top_requested.
  ///
  /// In en, this message translates to:
  /// **'Top Requested Services'**
  String get top_requested;

  /// No description provided for @saving_packages.
  ///
  /// In en, this message translates to:
  /// **'Saving Packages'**
  String get saving_packages;

  /// No description provided for @ourServices.
  ///
  /// In en, this message translates to:
  /// **'خدماتنا'**
  String get ourServices;

  /// No description provided for @fetching_location.
  ///
  /// In en, this message translates to:
  /// **'fetching your location...'**
  String get fetching_location;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'📍 currentLocation:'**
  String get currentLocation;

  /// No description provided for @offer.
  ///
  /// In en, this message translates to:
  /// **'Save up to 15% \n when you order now'**
  String get offer;

  /// No description provided for @requiredField.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get requiredField;

  /// No description provided for @housemaidoffer.
  ///
  /// In en, this message translates to:
  /// **'House Maid \n 7 days'**
  String get housemaidoffer;

  /// No description provided for @privateDriver.
  ///
  /// In en, this message translates to:
  /// **'Private Driver \n 7 days'**
  String get privateDriver;

  /// No description provided for @tenpercent.
  ///
  /// In en, this message translates to:
  /// **' %10 OFF'**
  String get tenpercent;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @designYourCard.
  ///
  /// In en, this message translates to:
  /// **'Design your card'**
  String get designYourCard;

  /// No description provided for @selectService.
  ///
  /// In en, this message translates to:
  /// **'Select Service'**
  String get selectService;

  /// No description provided for @hourlyServices.
  ///
  /// In en, this message translates to:
  /// **'Hourly Services'**
  String get hourlyServices;

  /// No description provided for @addNewAddress.
  ///
  /// In en, this message translates to:
  /// **'ADD NEW ADDRESS'**
  String get addNewAddress;

  /// No description provided for @selectAddressTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Address'**
  String get selectAddressTitle;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @nationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// No description provided for @professionals.
  ///
  /// In en, this message translates to:
  /// **'How many professionals do you need'**
  String get professionals;

  /// No description provided for @contractDuration.
  ///
  /// In en, this message translates to:
  /// **'Contract Duration'**
  String get contractDuration;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @durationOfVisit.
  ///
  /// In en, this message translates to:
  /// **'Duration of visit'**
  String get durationOfVisit;

  /// No description provided for @visitsWeeksNumber.
  ///
  /// In en, this message translates to:
  /// **'Visits week number'**
  String get visitsWeeksNumber;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get date;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @tapToSelect.
  ///
  /// In en, this message translates to:
  /// **'Tap to select'**
  String get tapToSelect;

  /// No description provided for @dialogForPrevious.
  ///
  /// In en, this message translates to:
  /// **'Please select Contract Duration and Visits Per Week first'**
  String get dialogForPrevious;

  /// No description provided for @selectNationality.
  ///
  /// In en, this message translates to:
  /// **'Select Nationality'**
  String get selectNationality;

  /// No description provided for @selectContractDuration.
  ///
  /// In en, this message translates to:
  /// **'Select Contract Duration'**
  String get selectContractDuration;

  /// No description provided for @selectTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Select Time Slot'**
  String get selectTimeSlot;

  /// No description provided for @selectVisitDuration.
  ///
  /// In en, this message translates to:
  /// **'Select Visit Duration'**
  String get selectVisitDuration;

  /// No description provided for @selectVisitsPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Select Visits Per Week'**
  String get selectVisitsPerWeek;

  /// No description provided for @noOfEmployee.
  ///
  /// In en, this message translates to:
  /// **'No of Employee'**
  String get noOfEmployee;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @weeklyVisits.
  ///
  /// In en, this message translates to:
  /// **'Weekly Visits'**
  String get weeklyVisits;

  /// No description provided for @totalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total Price'**
  String get totalPrice;

  /// No description provided for @packageDetails.
  ///
  /// In en, this message translates to:
  /// **'Package Details'**
  String get packageDetails;

  /// No description provided for @get.
  ///
  /// In en, this message translates to:
  /// **'GET'**
  String get get;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get off;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @weeks.
  ///
  /// In en, this message translates to:
  /// **'Weeks'**
  String get weeks;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @insertAddress.
  ///
  /// In en, this message translates to:
  /// **'Insert Address'**
  String get insertAddress;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @addressTitle.
  ///
  /// In en, this message translates to:
  /// **'Address Title'**
  String get addressTitle;

  /// No description provided for @houseType.
  ///
  /// In en, this message translates to:
  /// **'House Type'**
  String get houseType;

  /// No description provided for @buildingNum.
  ///
  /// In en, this message translates to:
  /// **'Building Number'**
  String get buildingNum;

  /// No description provided for @streetName.
  ///
  /// In en, this message translates to:
  /// **'Street Name'**
  String get streetName;

  /// No description provided for @villa.
  ///
  /// In en, this message translates to:
  /// **'Villa'**
  String get villa;

  /// No description provided for @appartment.
  ///
  /// In en, this message translates to:
  /// **'Appartment'**
  String get appartment;

  /// No description provided for @appartmentNumber.
  ///
  /// In en, this message translates to:
  /// **'Appartment'**
  String get appartmentNumber;

  /// No description provided for @flooeNumber.
  ///
  /// In en, this message translates to:
  /// **'Floor Number'**
  String get flooeNumber;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddress;

  /// No description provided for @houseNum.
  ///
  /// In en, this message translates to:
  /// **'House Number'**
  String get houseNum;

  /// No description provided for @floor.
  ///
  /// In en, this message translates to:
  /// **'Floor'**
  String get floor;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @selectCity.
  ///
  /// In en, this message translates to:
  /// **'Please select your city'**
  String get selectCity;

  /// No description provided for @selectDistrict.
  ///
  /// In en, this message translates to:
  /// **'Please select your District'**
  String get selectDistrict;

  /// No description provided for @selectMap.
  ///
  /// In en, this message translates to:
  /// **'Select on map'**
  String get selectMap;

  /// No description provided for @selectAddress.
  ///
  /// In en, this message translates to:
  /// **'Please give the address a name'**
  String get selectAddress;

  /// No description provided for @selectHouseType.
  ///
  /// In en, this message translates to:
  /// **'Select House Type'**
  String get selectHouseType;

  /// No description provided for @selectFloor.
  ///
  /// In en, this message translates to:
  /// **'Select floor'**
  String get selectFloor;

  /// No description provided for @selectNote.
  ///
  /// In en, this message translates to:
  /// **'Unit Number,Entrance code etc..'**
  String get selectNote;

  /// No description provided for @selectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get selectLocation;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @mapSelected.
  ///
  /// In en, this message translates to:
  /// **'Map selected'**
  String get mapSelected;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @ofStep.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get ofStep;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @congratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations!'**
  String get congratulations;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'saved so far!'**
  String get saved;

  /// No description provided for @viewOrder.
  ///
  /// In en, this message translates to:
  /// **'View Order'**
  String get viewOrder;

  /// No description provided for @orderSummary.
  ///
  /// In en, this message translates to:
  /// **'Order Summary'**
  String get orderSummary;

  /// No description provided for @serviceDetails.
  ///
  /// In en, this message translates to:
  /// **'Service Details'**
  String get serviceDetails;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @workers.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get workers;

  /// No description provided for @finalPrice.
  ///
  /// In en, this message translates to:
  /// **'Final Price'**
  String get finalPrice;

  /// No description provided for @billingPayment.
  ///
  /// In en, this message translates to:
  /// **'Billing and Payment'**
  String get billingPayment;

  /// No description provided for @coupons.
  ///
  /// In en, this message translates to:
  /// **'Coupons and Offers'**
  String get coupons;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get paymentSummary;

  /// No description provided for @itemTotal.
  ///
  /// In en, this message translates to:
  /// **'Item Total'**
  String get itemTotal;

  /// No description provided for @packDiscount.
  ///
  /// In en, this message translates to:
  /// **'Pack Discount'**
  String get packDiscount;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get month;

  /// No description provided for @visitWeekly.
  ///
  /// In en, this message translates to:
  /// **'Visit Weekly'**
  String get visitWeekly;

  /// No description provided for @savedSummary.
  ///
  /// In en, this message translates to:
  /// **'Yay! You have saved'**
  String get savedSummary;

  /// No description provided for @onFinalBill.
  ///
  /// In en, this message translates to:
  /// **'on final bill'**
  String get onFinalBill;

  /// No description provided for @agreement.
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get agreement;

  /// No description provided for @termsAndCond.
  ///
  /// In en, this message translates to:
  /// **'Terms and Conditions'**
  String get termsAndCond;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @proceedToPay.
  ///
  /// In en, this message translates to:
  /// **'Proceed to pay'**
  String get proceedToPay;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @totalIncVat.
  ///
  /// In en, this message translates to:
  /// **'Total (Inclusive of VAT)'**
  String get totalIncVat;

  /// No description provided for @eastAsia.
  ///
  /// In en, this message translates to:
  /// **'East Asia'**
  String get eastAsia;

  /// No description provided for @africa.
  ///
  /// In en, this message translates to:
  /// **'African'**
  String get africa;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @serviceContractId.
  ///
  /// In en, this message translates to:
  /// **'Service Contract ID'**
  String get serviceContractId;

  /// No description provided for @contractId.
  ///
  /// In en, this message translates to:
  /// **'Contract ID'**
  String get contractId;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @vat.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get vat;

  /// No description provided for @notConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get notConfirmed;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @hourlyService.
  ///
  /// In en, this message translates to:
  /// **'Hourly Service'**
  String get hourlyService;

  /// No description provided for @payNow.
  ///
  /// In en, this message translates to:
  /// **'Pay Now'**
  String get payNow;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @noPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'No phone number'**
  String get noPhoneNumber;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @myAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get myAddresses;

  /// No description provided for @myInformation.
  ///
  /// In en, this message translates to:
  /// **'My Information'**
  String get myInformation;

  /// No description provided for @myContracts.
  ///
  /// In en, this message translates to:
  /// **'My contracts'**
  String get myContracts;

  /// No description provided for @aboutCompany.
  ///
  /// In en, this message translates to:
  /// **'About the Company'**
  String get aboutCompany;

  /// No description provided for @ticketsSupport.
  ///
  /// In en, this message translates to:
  /// **'Tickets support'**
  String get ticketsSupport;

  /// No description provided for @companyBranches.
  ///
  /// In en, this message translates to:
  /// **'Company Branches'**
  String get companyBranches;

  /// No description provided for @socialMediaLinks.
  ///
  /// In en, this message translates to:
  /// **'Social Media Links'**
  String get socialMediaLinks;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions (FAQ)'**
  String get faq;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// No description provided for @userID.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get userID;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
