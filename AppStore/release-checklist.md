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

## Premium IAP

- [x] `AppFeatures.inAppPurchasesEnabled = true` for Debug and Release.
- [x] Free access limited to 30 questions; Premium unlocks all questions and modes.
- [x] Premium entitlement disables AdMob before SDK initialization and hides an active banner immediately after purchase.
- [x] Product loading, transaction listener, purchase and restore enabled.
- [ ] Non-consumable `com.viuniverse.pspo.one.premium` attached to this submission.
- [x] EN-US and VI metadata, screenshots and review notes describe Premium and ad removal accurately.
- [ ] Purchase, pending, cancel, restore and revoke tested with StoreKit configuration and sandbox.

## Assets

- [ ] iPhone 6.9-inch screenshots, 1–10 PNG/JPG, same accepted size.
- [ ] iPad 13-inch screenshots because the app supports iPad.
- [ ] No alpha/transparency in screenshots.
- [ ] Screenshots avoid unlicensed marks and unsupported claims.
- [ ] App icon reviewed at small size; reconsider year-specific “2026” artwork and prominent `PSPO I` mark before release.

## Build

- [x] `bash Tests/run.sh` passes.
- [x] Release archive built with Xcode 26.3 / iOS 26.2 SDK.
- [x] Version `1.0.1`, build `1` confirmed in archive and IPA.
- [x] Minimum OS `17.0` confirmed.
- [x] `PrivacyInfo.xcprivacy` exists in app bundle.
- [x] `ITSAppUsesNonExemptEncryption = NO` exists in built Info.plist.
- [x] Local archive validation passes; only the non-blocking AppIntents metadata extraction warning remains.
- [x] IPA signed for Apple Developer Team `7GH7MJS7R2` with Cloud Managed Apple Distribution.
- [x] `codesign --verify --deep --strict` passes for the exported build 1 app; `get-task-allow = false`.
- [x] StoreKit test configuration excluded from the app bundle.
- [x] App Store IPA exported at `build/20260925-1.0.1-build1-111817/ipa/PSPOPrep-1.0.1-1.ipa`.
- [ ] Upload through Xcode Organizer or Transporter.
- [ ] Processed build selected in version 1.0.1.
- [ ] Export compliance shows no missing compliance.

## Final review

- [ ] Free users receive 30 questions and see PRO/paywall gates at every Premium entry point.
- [ ] Premium users receive all parts, 80-question exams, Flash, Time Trial, bookmarks and review without ads.
- [ ] Premium entitlement survives relaunch; restore re-enables Premium; revoke returns the app to free access.
- [ ] Privacy policy matches actual Firebase Analytics behavior.
- [ ] Reviewer notes pasted from `app-review.md`.
- [ ] Manual release selected for first production launch.
