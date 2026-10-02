# App Store Connect entry sheet · Cup Season 1.0 (build 2114)

Field-by-field values for the existing 1.0 draft (PREPARE_FOR_SUBMISSION). The copy comes
from [the package](app-store-package-2026-09-30.md): Part A §1–§10, C-1 and C-2 with the
rulings recorded in D402 and D403. **Entered through the API on 2026-10-01 on the owner's yes,
and read back:** App Information, Pricing and Availability, the age rating answers and every
Version 1.0 field except the screenshots (the package's "Deployed" table); **the screenshots followed
on 2026-10-02** (the nine approved frames). **Still the owner's,
in App Store Connect:** the App Review contact phone and the reviewer **password** (Apple
refused the review detail without the phone), the notes paste, App Privacy (no API), the
content rights answer. Never write the
password or the phone into this repo.

## App Information

| Field | Value |
|---|---|
| Name | `Cup Season` |
| Subtitle | `Golf where every round counts` (the package's recommendation; alternatives in §2) |
| Primary category | Sports |
| Secondary category | Lifestyle |
| Privacy Policy URL | `https://cupseason.app/legal.html#privacy` |
| Content rights | **Owner's answer.** Recommended: "Yes, it contains, shows or accesses third-party content, and I have the necessary rights". The app shows course data from GolfCourseAPI and weather from Open-Meteo under their terms, and `legal.html` names both. |
| Age rating | See below. Apple computes the rating; expect 13+ and read it back. |

## Pricing and Availability

| Field | Value |
|---|---|
| Price | Free (USD 0.00), base territory United States |
| Availability | **United States only.** Untick "make available in new countries or regions automatically". |
| Distribution | Public App Store, no pre-order |

## Version 1.0

| Field | Value |
|---|---|
| Promotional text | §3 (150/170) |
| Description | §4 (2,366/4,000), including THE POT paragraph. D402: publishable now that the $200 phone cap and the money-door labels ship in this build. |
| Keywords | §5: `handicap,skins,wolf,match,play,scorecard,league,standings,buddies,friends,rivalry,score,tee,live` |
| Support URL | `https://cupseason.app/support` |
| Marketing URL | `https://cupseason.app` |
| Copyright | `2026 Fischbeck3 LLC` |
| Version release | **Manually release this version** (currently AFTER_APPROVAL) |
| Build | **1.0.0 (2114), from `c8cd8ea3`**, the same files as main's `ebbbfea3` (candidate 3, the owner's yes on 2026-10-02; it replaced 2097, which had replaced 2094). Export compliance is answered in the binary (`ITSAppUsesNonExemptEncryption = NO`). |
| Screenshots (iPhone 6.9") | **Uploaded 2026-10-02 on the owner's yes ("All 9, with widgets"):** the nine frames of `apps/ios/Screenshots/1.0`, in §9 order, replaced all 8 September 25 frames; each read back COMPLETE at 1320 × 2868 with its checksum matching the committed file. To redo: `~/cup-season-store-shots/asc/asc_metadata.py --apply --only screenshots --shots apps/ios/Screenshots/1.0 --display APP_IPHONE_67` (dry run first, without `--apply`) |

## App Review Information

| Field | Value |
|---|---|
| Contact | the owner's name · `jerecho@fischbeck3.com` (the support page's address) · phone: **owner enters (+1 format)** |
| Sign-in required | Yes |
| User name | `reviewer@cupseason.app` |
| Password | **Owner enters in App Store Connect only** (works on build 2114, check R1) |
| Notes | [`app-review-notes-1.0.txt`](app-review-notes-1.0.txt), verbatim (3,949 bytes) |

## Age rating answers (C-2 with the rulings)

| Question | Answer |
|---|---|
| Parental Controls · Age Assurance · Unrestricted Web Access · Advertising | No |
| User-Generated Content · Messaging and Chat | Yes |
| Social Media | Yes: a feed of buddies' rounds with applause and comments fits Apple's definition |
| Social Media disabled for under-13s | No |
| Contests | Frequent |
| Gambling | No (D402) |
| Simulated Gambling | Infrequent (pride bets; D402: changes nothing with Contests at Frequent) |
| Alcohol, Tobacco or Drug Use or References | Infrequent ("The Beverage" marker, "Loser buys the beers") |
| Profanity or Crude Humor; Loot Boxes; Health or Wellness; Medical; Horror; Mature; Sexual; Violence; Guns | None / No |

## App Privacy (C-1; the owner agreed 2026-10-01; App Store Connect UI only)

Every type is **linked** to the user, **not** used for tracking. Tracking: No.

| Collect | Purpose |
|---|---|
| Name, Email Address, User ID, Device ID, Photos or Videos, Other User Content, Customer Support, Crash Data, Performance Data, Other Diagnostic Data, Emails or Text Messages, Contacts | App Functionality |
| Product Interaction | Analytics |
| Other Financial Info | App Functionality (declared: the ledger records buy-ins, who has paid and settlement totals) |

Not collected: location (coarse or precise), health, fitness, payment info, purchases,
browsing, search, sensitive info, audio, advertising data.
