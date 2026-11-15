# Store privacy answers (anonymous usage statistics)

Prepared answers for **App Store Connect → App Privacy** and **Google Play
Console → Policy → App content → Data safety**, for the first build that
sends anonymous usage statistics (`docs/telemetry.md`,
`DevConventions/Prompts/04-PLAN-analytika.md`).

Order: new `docs/privacy.html` live (merge of this PR) → these forms →
`TELEMETRY_KEY` / `TELEMETRY_HOST` secrets → release. A build without the
secrets sends nothing, so the old answers stay correct until then.

Check the current wording of both forms before filling them in; the
categories below are the ones in use in November 2026.

## What is sent (summary for both forms)

- Screens shown and seconds on them, filters and collections picked,
  first use of a feature in a session, start and outcome of saving,
  sharing, recording and purchasing (with seconds), deep links opened,
  error types shown. App version, platform, language, "owns a paid
  collection" yes/no, coarse session and day bands.
- On Android, the first record of a new install may carry the campaign
  name from the Play install referrer (for example a QR code placement).
- **Never** anything about the content of a photo or video, no identifier,
  no device model, no free text.
- Received by the developer's own server in the EU (Czech Republic). No
  third party gets the events. The IP address is not stored; the server
  keeps only the country. Raw events are kept 12 months.
- Can be turned off in the app (gear button on the camera screen); off
  deletes the unsent records at once.

## App Store Connect → App Privacy

**Do you or your third-party partners collect data from this app?** **Yes.**

**Data types collected** (tick exactly these):

| Category → type | Linked to the user? | Used for tracking? | Purpose |
|---|---|---|---|
| Usage Data → **Product Interaction** | **No** | **No** | **Analytics** |
| Diagnostics → **Performance Data** | **No** | **No** | **Analytics** |
| Location → **Coarse Location** | **No** | **No** | **Analytics** |

Why each:

- *Product Interaction*: launches, screens, filter picks, feature use,
  save / share / record / purchase starts and outcomes.
- *Performance Data*: how many seconds saving a photo or video takes, and
  whether the full-resolution capture had to fall back to a screen capture.
- *Coarse Location*: the statistics server derives the country from the
  connection's IP address and keeps only the country. If the owner turns
  the country off at the collector, untick this row and remove
  `NSPrivacyCollectedDataTypeCoarseLocation` from both privacy manifests
  (`mirrorbooth/ios/Runner/PrivacyInfo.xcprivacy`,
  `mirrorbooth/macos/Runner/PrivacyInfo.xcprivacy`).

Not collected (leave unticked): Contact Info, Health & Fitness, Financial
Info, Precise Location, Sensitive Info, Contacts, **User Content (photos,
videos and audio never leave the device)**, Browsing History, Search
History, Identifiers (no User ID and no Device ID: the session id is
random, lives in memory and is never reused), Purchases (the purchase
events say which collection was bought, not who bought it; the store's
own purchase history is Apple's data), Other Usage Data, Crash Data,
Other Diagnostic Data, Other Data.

**Linked to the user: No**, for every type: no account, no identifier; two
sessions cannot be connected to each other.

**Tracking: No.** Nothing is combined with other companies' data or shared
with data brokers, and there is no advertising. No App Tracking
Transparency prompt is needed (`NSPrivacyTracking` is `false`).

## Google Play → Data safety

- Does your app collect or share any of the required user data types?
  **Yes.**
- Is all of the user data collected by your app encrypted in transit?
  **Yes** (the statistics client refuses a non-`https` host).
- Do you provide a way for users to request that their data be deleted?
  **No.** There is no account. The statistics carry no identifier, so no
  record can be found for a person; they can be switched off in the app
  (which deletes the unsent ones on the device) and are deleted after 12
  months. Deletion requests are required only for apps with account
  creation.
- Data types, all **Collected**, **not shared** (the developer's own server
  is not a third party):

| Data type | Purpose | Processed ephemerally? | Required or optional |
|---|---|---|---|
| App activity → **App interactions** | **Analytics** | No | **Optional** (switch behind the gear button) |
| App info and performance → **Diagnostics** | **Analytics** | No | **Optional** (same switch) |
| Location → **Approximate location** | **Analytics** | No | **Optional** (same switch) |

*Diagnostics* covers the save durations; *Approximate location* is the
country derived from the IP address by the collector. Drop that row if the
country is turned off at the collector.

Not collected: precise location, personal info, financial info (purchases
are Play Billing's data, not ours), **photos and videos** (never uploaded),
audio, files and docs, messages, contacts, calendar, web browsing, device
or other IDs (the advertising ID is not used).

IARC "Collects or shares personal info": stays **No** (nothing personal).
Advertising ID declaration: stays **No**.

## Outside this repository

- App Store Connect → App Privacy (answers above).
- Google Play Console → Data safety (answers above).
- The app's page on olin.now (`ol1n.now` repo), in every language it
  exists in: any sentence saying the app sends nothing or has no analytics.
- App Store description and promotional text in App Store Connect for the
  locales not kept in `store/appstore/metadata` (the descriptions are not
  in this repo): replace "no analytics" with "no third-party analytics".
