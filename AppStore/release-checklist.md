# Release checklist

## Legal and account

- [ ] DSA trader status completed if distributing in the EU.
- [ ] Content rights for all 800 questions and explanations documented.
- [ ] Trademark/name usage reviewed; independent-app disclaimer retained.
- [ ] App Review contact name, email and international phone completed.

## App Store Connect record

- [ ] App name reserved: PSPOPrep.
- [ ] Bundle ID selected: `com.viuniverse.pspo-one`.
- [ ] SKU entered: `pspo-prep-ios-2026`.
- [ ] Primary/secondary categories set.
- [ ] EN-US and VI metadata entered.
- [ ] Support, marketing and privacy URLs entered.
- [ ] Support page app selector includes PSPOPrep.
- [ ] Privacy policy explicitly covers PSPOPrep and Firebase Analytics.
- [ ] App Privacy answers entered from `privacy.md`.
- [ ] Updated age-rating questionnaire completed from `age-rating.md`.
- [ ] Content rights question answered only after license confirmation.
- [ ] Accessibility Nutrition Labels left blank until VoiceOver/Larger Text audit passes, or entered accurately.

## First release: no IAP

- [x] `AppFeatures.inAppPurchasesEnabled = false` for Debug and Release.
- [x] All 800 questions and every study mode included without a transaction.
- [x] Product loading, transaction listener, purchase and restore disabled.
- [ ] No IAP product attached to this submission; no IAP promotion enabled.
- [ ] EN-US and VI metadata describe full access without a purchase.
- [ ] Screenshots contain no paywall or Premium promotion.

## Assets

- [ ] iPhone 6.9-inch screenshots, 1–10 PNG/JPG, same accepted size.
- [ ] iPad 13-inch screenshots because the app supports iPad.
- [ ] No alpha/transparency in screenshots.
- [ ] Screenshots avoid unlicensed marks and unsupported claims.
- [ ] App icon reviewed at small size; reconsider year-specific “2026” artwork and prominent `PSPO I` mark before release.

## Build

- [x] `bash Tests/run.sh` passes.
- [x] Release archive built with Xcode 26.3 / iOS 26.2 SDK.
- [x] Version `1.0.0`, build `5` confirmed in archive and IPA.
- [x] Minimum OS `17.0` confirmed.
- [x] `PrivacyInfo.xcprivacy` exists in app bundle.
- [x] `ITSAppUsesNonExemptEncryption = NO` exists in built Info.plist.
- [x] Local archive validation passes; only the non-blocking AppIntents metadata extraction warning remains.
- [x] IPA signed for Apple Developer Team `7GH7MJS7R2` with Cloud Managed Apple Distribution.
- [x] `codesign --verify --deep --strict` passes for the exported build 5 app; `get-task-allow = false`.
- [x] StoreKit test configuration excluded from the app bundle.
- [ ] Upload through Xcode Organizer or Transporter.
- [ ] Processed build selected in version 1.0.0.
- [ ] Export compliance shows no missing compliance.

## Final review

- [ ] All parts, 80-question exams, Flash, Time Trial, bookmarks and review work without purchase or login.
- [ ] No paywall, purchase, restore, redeem-code buttons or PRO locks in either language.
- [ ] Full access survives relaunch, offline use and restoring a saved draft.
- [ ] Privacy policy matches actual Firebase Analytics behavior.
- [ ] Reviewer notes pasted from `app-review.md`.
- [ ] Manual release selected for first production launch.
