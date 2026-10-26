# Wee Alarm — App Store submission pack

Everything you need to paste into App Store Connect, plus a checklist to get through review first time.

---

## 1. App information

| Field | Value |
|---|---|
| Name | **Wee Alarm** (if taken: *Wee Alarm: Dog Potty Timer*) |
| Subtitle (30 max) | **Dog potty break reminders** (25) |
| Bundle ID | `com.geodude117.WeeAlarm` |
| SKU | `wee-alarm-ios` |
| Primary category | Lifestyle |
| Secondary category | Utilities |
| Price | Free |
| Copyright | 2026 Geovan |
| Privacy Policy URL | https://geodude117.github.io/Portfolio/wee-alarm/privacy/ |
| Support URL | https://geodude117.github.io/Portfolio/wee-alarm/ |
| Marketing URL (optional) | https://geodude117.github.io/Portfolio/wee-alarm/ |

## 2. Version 1.0 text

**Promotional text** (170 max, can change any time without review)

> Gaming or working and lost track of time? Wee Alarm rings when your dog needs to go out, even on silent, and gets more fidgety the closer it gets.

**Keywords** (100 max, comma-separated, no spaces; words already in the name and subtitle are left out because Apple indexes those anyway)

```
puppy,pee,toilet,training,timer,pet,housetraining,walk,bladder,pup,outside,gaming,focus,loo,poo
```

**Description**

> Never forget to let the dog out again.
>
> Wee Alarm is a simple alarm for dog owners who get lost in a game, a work call or a good show. Tell it about your dog, and it rings when it's time for a wee break — even if your phone is on silent or in a Focus mode.
>
> SET UP IN SECONDS
> • Enter your dog's name, age and size
> • Get a suggested wee-break interval, then adjust it to suit your dog
>
> A REAL ALARM
> • Rings through silent mode and Focus
> • Tap Let out on the alarm and the next timer starts automatically
> • Snooze for 15 minutes when you can't step away yet
> • Quiet hours keep the night alarm-free
>
> A DOG WITH OPINIONS
> • A friendly animated dog that gets more fidgety as wee time gets closer
> • Watch the bladder meter fill up, then drain with a burst of paw prints when you let them out
>
> PRIVATE BY DESIGN
> • No accounts, no ads, no tracking
> • Everything stays on your iPhone
>
> Suggested intervals are a general guide, not veterinary advice. If your dog has a health condition, ask your vet how often they need to go out.

**What's New** (for 1.0, Apple fills this in automatically; for later versions write one or two lines)

## 3. App Privacy (the "nutrition label")

In App Store Connect → **App Privacy** → **Get Started**:

- "Do you or your third-party partners collect data from this app?" → **No, we do not collect data from this app**
- Result shown on the store: **Data Not Collected**

This matches the privacy policy and the `PrivacyInfo.xcprivacy` manifest in the app.

## 4. Age rating questionnaire

Answer **None / No** to every question (violence, sexual content, profanity, drugs, gambling, horror, medical information, user-generated content, messaging, web access, contests, advertising, parental controls not needed). The rating should come out as **4+**.

## 5. Export compliance

Already handled: `ITSAppUsesNonExemptEncryption = NO` is in `Config/Info.plist`, so App Store Connect won't ask on every upload.

## 6. App Review information

- **Sign-in required:** No
- **Contact:** your name, phone and email (only Apple sees these)
- **Notes for the reviewer** (paste this):

> Wee Alarm reminds dog owners to let their dog out for a wee.
>
> No account or login is needed. To test:
> 1. Launch the app and complete the 3-step setup (any dog name, age and size), then tap Start and allow alarms.
> 2. The home screen shows a countdown to the next wee break. Tapping "Let out" restarts the timer.
> 3. The shortest interval is 1 hour, so to hear an alarm quickly, open Settings (gear icon) and tap "Test the alarm". An alarm rings after 1 minute, including when the device is locked and on silent. The alarm has a "Let out" button that logs the break and starts the next timer.
>
> The app uses AlarmKit for alarms (NSAlarmKitUsageDescription is set) and falls back to a standard local notification if alarms aren't allowed. It collects no data and makes no network requests. Suggested intervals are presented as a general guide with a note to ask a vet; the app makes no medical claims.

## 7. Screenshots

Required: **one set for 6.9" iPhone**, portrait, **1320 × 2868** (1290 × 2796 also accepted). Between 1 and 10 images; aim for 5.

Take them in the **iPhone 17 Pro Max simulator** (it captures at 1320 × 2868) with **File → Save Screen** (⌘S) in the Simulator. Suggested set, with optional caption text:

1. Home screen, happy dog, bladder about a third full — *"Never forget the wee break"*
2. Home screen, overdue, dog doing the potty dance — *"It knows when it's time"*
3. Ringing alarm on the lock screen (use Test the alarm) — *"Rings even on silent"*
4. Setup step 3 showing the recommended interval — *"Set up in seconds"*
5. Settings with quiet hours — *"Quiet nights"*

Rules that cause rejections: screenshots must show the real app, no device frames are required, and no fake system UI or other companies' logos.

### Ready-made images

- `AppStore/screenshots/iPhone-6.9-inch/` (1320 × 2868), `iPhone-6.5-inch/` (1284 × 2778), `iPhone-6.3-inch/` (1206 × 2622): six captioned screenshots each, in upload order. Only the 6.9" set is required; App Store Connect scales it for smaller iPhones.
- `AppStore/screenshots/raw-iPhone-18-Pro-Max/`: the original simulator captures.
- `AppStore/creative/`: optional Header (3840 × 1646) and Search Results (3840 × 2560) images, plus a 16:9 image (5244 × 2950) that works for both.
- Regenerate with `Branding/make_screenshots.py` and `Branding/make_store_assets.py`.
- In Debug builds, triple-tap the dog's name on the home screen to jump the timer to 35%, 85%, due in 20 seconds, or overdue, for taking screenshots.

## 8. Pre-submission checklist

**Account and project**
- [ ] Apple Developer Program membership is active
- [ ] Bundle ID `com.geodude117.WeeAlarm` registered (Xcode does this automatically with automatic signing)
- [ ] Xcode → WeeAlarm target → Signing & Capabilities → your team selected
- [ ] Version `1.0`, build `1` (increase the build number for every upload)

**Test on a real iPhone**
- [ ] Fresh install → setup → Start → alarm permission prompt appears with the right wording
- [ ] Test the alarm rings on silent, locked, and in a Focus mode
- [ ] Let out button on the alarm restarts the timer without opening the app
- [ ] Deny alarms → a notification arrives instead, and the home screen shows the "Alarms are off" banner
- [ ] Quiet hours push a late alarm to the morning
- [ ] Start over returns to setup
- [ ] Privacy policy and support links in Settings open the right pages
- [ ] Light and dark mode both look right; text is readable at large Dynamic Type sizes
- [ ] No crashes during a 10-minute session (App Review rejects crashes under guideline 2.1)

**Upload**
- [ ] Product → Archive (with "Any iOS Device" selected)
- [ ] Organizer → Distribute App → App Store Connect → Upload
- [ ] Optional but recommended: install the build through TestFlight and repeat the device tests
- [ ] Fill in sections 1–7 above in App Store Connect, attach the build, and Submit for Review

**Website**
- [ ] Privacy policy and support pages are live at the URLs in section 1 before you submit (App Review opens them)

## 9. Rejection risks and how the app handles them

| Guideline | Risk | What's in place |
|---|---|---|
| 2.1 App completeness | Crashes, placeholder text, broken links | Device test checklist above; live policy and support pages |
| 4.2 Minimum functionality | "Just a timer" apps can be rejected as too simple | Real AlarmKit alarm with an action button, recommendations, quiet hours, snooze, test alarm, animated character |
| 5.1.1 Privacy | Missing or inaccurate privacy policy or labels | Policy URL in App Store Connect and in Settings; "Data Not Collected"; privacy manifest for UserDefaults |
| 1.4.1 Health | Advice presented as medical fact | Intervals labelled as a general guide, "not veterinary advice", in setup, Settings and the description |
| 2.3 Accurate metadata | Screenshots or text that don't match the app | Screenshots taken from the real app; description lists only real features |
| 5.1.1(iv) Permissions | Asking for permission without context | Alarm permission is requested after setup explains the alarm, with a clear usage description |
