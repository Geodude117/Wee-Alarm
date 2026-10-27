# App Review reply (Guideline 2.1 information request)

Paste the text below into the Resolution Center reply **and** into
App Review Information → Notes. It is under the 4,000-character Notes limit.

---

Hello App Review team,

Thank you for reviewing Wee Alarm. Here is the information you requested. A screen recording from a physical iPhone running iOS 27 is attached to this reply.

1. SCREEN RECORDING
The attached recording was captured on a physical iPhone running the latest iOS. It starts by launching the app and shows the typical flow: the 3-step setup (dog name, age and size, recommended interval), allowing alarms, the home screen countdown, the Settings screen, "Test the alarm", the alarm ringing with the device locked and on silent, tapping "Let out" on the alarm, and the timer restarting.
The app has no account registration, login or account deletion, no user-generated content, and no paid content, subscriptions or In-App Purchases.

2. PURPOSE AND TARGET AUDIENCE
Wee Alarm is a simple reminder for dog owners to let their dog out for a toilet break. It is aimed at adults who lose track of time while gaming, working or watching TV. It suggests a break interval based on the dog's age and size (presented as a general guide, not veterinary advice), then rings a real alarm when the break is due, even in silent mode or a Focus mode, so the dog isn't left waiting.

3. HOW TO SET UP AND USE THE MAIN FEATURES
No login, demo account or sample files are needed.
- Launch the app, enter any dog name, tap Next, choose an age and size, tap Next, then tap Start and allow alarms when asked.
- The home screen shows a countdown and a "bladder" meter that fills up as the break gets closer. Tap "Let out" to log a break and restart the timer.
- Tap the gear icon to change the dog, the interval and quiet hours (no alarms overnight).
- The shortest interval is 1 hour. To hear an alarm quickly, open Settings and tap "Test the alarm"; an alarm rings after 1 minute, including when the device is locked and on silent. Tapping the paw ("Let out") button on the alarm logs the break and starts the next timer without opening the app.
- If alarms are not allowed, the app falls back to a standard local notification with "Let out" and "Snooze 15 min" actions.

4. EXTERNAL SERVICES
The app uses no external or third-party services. It makes no network requests and has no analytics, advertising, authentication, payment or AI services. It uses only Apple system frameworks on the device: AlarmKit (alarms), UserNotifications (fallback notifications), App Intents (the "Let out" alarm button) and SwiftUI. All data (the dog's name, age, size, interval, quiet hours and last break time) is stored only on the device.

5. REGIONAL DIFFERENCES
There are no regional differences. The app's features and content are the same in every region where it is available.

6. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
Not applicable. The app does not operate in a regulated industry and contains no protected third-party material. All artwork, including the dog character and icon, was created for this app. The suggested intervals are labelled in the app and on the App Store as a general guide and not veterinary advice.

Privacy policy: https://geodude117.github.io/Portfolio/wee-alarm/privacy/
Support: https://geodude117.github.io/Portfolio/wee-alarm/

Thank you,
Geovan Inacay

---

## Recording checklist (on your iPhone)

1. Install the build from TestFlight on your iPhone (iOS 27).
2. Delete any earlier copy of the app first, so setup and the alarm permission prompt appear.
3. Settings → Control Centre → add **Screen Recording**.
4. Start recording from Control Centre, then:
   1. Launch Wee Alarm from the Home Screen.
   2. Do the 3-step setup and tap **Allow** on the alarm prompt.
   3. Show the home screen and tap **Let out**.
   4. Open Settings (gear), scroll through, tap **Test the alarm**, tap **Done**.
   5. Lock the phone (silent switch on) and wait about a minute until the alarm rings.
   6. Tap the paw **Let out** button, unlock, and show the timer has restarted.
5. Stop recording. Attach the video from Photos to the reply in App Store Connect.
