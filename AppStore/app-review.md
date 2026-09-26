# App Review Information — Guideline 2.1

Replace the two remaining placeholders, then paste this into both the App Review reply and the **Notes** field.

## Response

Hello App Review,

1. **Screen recording:** `[ATTACH VIDEO OR ADD LINK]`. Record app version `1.0.1 (1)` on a current physical iPhone. Show launch, onboarding, profile setup, free practice, the Premium paywall, purchase restoration, bookmarks, Saved, mock exam, results, review, study modes, and settings. The app has no accounts or user-generated content.

2. **Purpose and audience:** PSPOPrep is an independent study app for Product Owners, Scrum practitioners, and learners preparing for PSPO I. It provides 800 practice questions, explanations, timed mock exams, focused review, bookmarks, and local progress tracking.

3. **Access and purchase review:** No login, credentials, VPN, or sample files are required. Launch the app, complete or skip onboarding, then open Profile → “Unlock the full question bank.” The non-consumable product is `com.viuniverse.pspo.one.premium` (“Premium Lifetime Access”). Free users can access 30 questions. Premium permanently unlocks all 800 questions, all study modes, and removes ads. “Restore purchase” is available on the same paywall. Notification permission is optional.

4. **External services:** StoreKit 2 handles the non-consumable purchase and restoration. Firebase Analytics records anonymous usage events. Apple UserNotifications provides optional local reminders. Google Mobile Ads provides free-tier ad placements when production ad units are configured; verified Premium entitlement disables ad requests and removes loaded ads. Progress is stored locally with UserDefaults. The app has no backend, authentication, cloud sync, AI service, or external payment processor.

5. **Regions:** Features, content, and free access are the same in every region. The interface supports English and Vietnamese; study questions are in English.

6. **Regulated or protected material:** The app is an educational study aid and provides no regulated services. It is not affiliated with or endorsed by Scrum.org. `[STATE THAT THE 800 QUESTIONS ARE ORIGINAL, OR IDENTIFY THE LICENSE OWNER AND ATTACH THE OWNERSHIP/LICENSE DOCUMENT.]`

Thank you.

## Before sending

- [ ] Attach the physical-device recording or insert its accessible URL.
- [ ] Replace the question-bank ownership/license placeholder and attach proof.
- [ ] Add App Review contact name and international phone number in App Store Connect.
