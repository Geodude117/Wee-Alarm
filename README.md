# Wee Alarm 🐶

A tiny iPhone app that reminds you to let your dog out for a wee — built for when you're deep in a game or in work mode and lose track of time.

## What it does

- **Three-step setup:** your dog's name, age and size, then a recommended wee-break interval you can adjust.
- **A real alarm:** uses AlarmKit, so it rings even on silent or in a Focus mode. Falls back to a notification if alarms aren't allowed.
- **"Let out" from the alarm:** tap Let out on the ringing alarm and the next timer starts, without opening the app.
- **Quiet hours:** no alarms overnight (23:00–07:00 by default). A break that lands in quiet hours waits until the morning.
- **Snooze:** 15 more minutes when you can't step away yet.

## The fun bits

- An animated dog that blinks and wags its ears. It gets fidgety as wee time approaches and does the potty dance (with a sweat drop) when overdue.
- A "bladder" circle that fills with a wobbling yellow liquid. The waves get choppier the closer it gets, and it jiggles when overdue.
- Tapping **Let out** drains the bladder with a spring, bursts paw prints and gives a success haptic. The dog sticks its tongue out happily for a few seconds.
- In setup, the dog tilts its head when you type a name and grows or shrinks as you pick a size. A yellow pill slides between choices, and the interval number rolls as you change it.

## Requirements

- Xcode 26 or later
- iOS 26.1 or later (AlarmKit)

## Getting started

1. Open `WeeAlarm.xcodeproj`.
2. Select the **WeeAlarm** target → **Signing & Capabilities** → choose your team.
3. Run on a real iPhone. Alarms are best tested on a device with the phone silenced and a Focus mode on.

Run the tests with **⌘U**. They cover the recommendation rules, quiet hours, formatting and the store.

## Project layout

```
WeeAlarm/
  WeeAlarmApp.swift          App entry
  Model/
    DogProfile.swift         Dog, recommendation rules, quiet hours, schedule maths
    DogStore.swift           State + persistence (UserDefaults), drives the alarm
  Alarms/
    AlarmScheduler.swift     AlarmKit alarm, notification fallback
    LetOutIntent.swift       "Let out" button on the ringing alarm
    NotificationHandler.swift  Buttons on the fallback notification
  Design/
    Theme.swift              Colours, fonts, big button style
    DogFace.swift            The animated dog
    BladderView.swift        Liquid fill, waves, bubbles, paw burst
  Views/
    RootView.swift           Setup ↔ home switch
    OnboardingView.swift     3-step setup
    HomeView.swift           Countdown + Let out
    SettingsView.swift       Edit dog, interval, quiet hours, start over
WeeAlarmTests/               Swift Testing unit tests
Config/Info.plist            NSAlarmKitUsageDescription
```

## Recommended intervals

| Dog | Interval |
|---|---|
| Puppy | 2 hours |
| Adult | 4 hours |
| Senior | 3 hours |
| Small breed | 1 hour less |

This is a general guide. Dogs with health issues or on medication may need different timings, so check with your vet.
