# App Privacy

Privacy Policy URL: `https://viuniverse.com/privacy`

## App Store Connect answers

Select **Yes, we collect data from this app** because Firebase Analytics and its dependencies transmit analytics data.

| Data type | Purpose | Linked to user | Tracking |
| --- | --- | --- | --- |
| Location → Coarse Location | Analytics | No | No |
| Identifiers → Device ID | Analytics | No | No |
| Purchases → Purchase History | Analytics | No | No |
| Usage Data → Product Interaction | Analytics | No | No |
| Diagnostics → Other Diagnostic Data | Analytics | No | No |

Do not select name, email, user content, precise location, contacts, health, financial information, advertising data, crash data, or performance data for the current implementation.

## Local-only data

The following stays on device and does not count as “collected” for the App Privacy label:

- Learner name.
- Planned exam date.
- Study answers and scores.
- Drafts, bookmarks, missed and incorrect questions.
- Language and onboarding preferences.

## Tracking

- App Tracking Transparency prompt: No.
- IDFA access: No intentional access.
- Cross-app/site tracking: No.
- Developer-supplied Analytics user ID: No.
- Google Ads audience/export features: must remain disabled unless the privacy answers and ATT implementation are updated.

## Privacy manifest

`vipm/PrivacyInfo.xcprivacy` declares `UserDefaults` reason `CA92.1`. Firebase dependency manifests remain responsible for SDK API/data declarations.

Before publishing, verify `https://viuniverse.com/privacy` explicitly covers PSPOPrep, Firebase Analytics, app-instance identifiers, coarse location derived from masked IP, purchase events, retention, deletion/contact rights, and `support@viuniverse.com`.
