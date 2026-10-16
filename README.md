# Cadence

A privacy-focused, offline day planner for iOS. No account, no network, no
ads, no telemetry. Your plan lives on your device in a local SwiftData store
and nowhere else.

This is an **original** app inspired by the "visual day timeline" category of
planners. It is not a copy of any specific product — the data model, UI, and
code here are all original and MIT-licensed.

## Features (first version)

- **Day timeline** — a vertical, hour-by-hour view of a single day.
- **Tasks and events** — tasks can be checked off; events are fixed blocks.
  Each has a start time and a duration.
- **Recurrence** — none, daily, weekdays, weekly, or monthly. Recurring items
  are stored once as a template; occurrences are computed on the fly.
- **Local reminders** — optional notification N minutes before an item starts,
  scheduled entirely through the on-device notification center.
- **Per-day completion** — checking off a recurring task only completes that
  day's occurrence.

## Privacy

- No networking code. The app never opens a socket.
- No analytics, no crash reporters, no third-party SDKs.
- The only system permission requested is local notifications, and only if you
  add a reminder.

## Project layout

```
Cadence/
  CadenceApp.swift            App entry + local ModelContainer
  Models/
    PlannerItem.swift         SwiftData model (the template for recurring items)
    Recurrence.swift          Recurrence + ItemKind enums
  Services/
    RecurrenceEngine.swift    Computes occurrences for a given day
    NotificationManager.swift Local reminder scheduling
  Views/
    ContentView.swift
    DayTimelineView.swift     Day header + scrollable timeline
    TimelineBlockView.swift   One item block
    ItemEditorView.swift      Add / edit / delete sheet
```

## Building an .ipa without a Mac (GitHub Actions)

Apple's build tools only run on macOS, but you don't need to *own* a Mac — the
included workflow builds on GitHub's free hosted macOS runner and hands you an
**unsigned** `.ipa`. AltStore / Sideloadly then re-sign it with your own Apple
ID when they install it, so no signing secrets ever touch CI.

1. Create a new GitHub repository and push this folder to it:
   ```bash
   cd Cadence
   git init && git add . && git commit -m "Cadence: offline day planner"
   git branch -M main
   git remote add origin https://github.com/<you>/cadence.git
   git push -u origin main
   ```
2. On GitHub, open the **Actions** tab. The *Build unsigned IPA* workflow runs
   on push (or run it manually with **Run workflow**).
3. When it finishes, open the run and download the **Cadence-unsigned-ipa**
   artifact. Unzip it to get `Cadence-unsigned.ipa`.
4. Install it on your iPhone:
   - **Sideloadly** (Windows/Linux/Mac) or **AltStore** — point it at the
     `.ipa`, sign in with your Apple ID, and install. A free Apple ID works;
     the app just needs re-installing every 7 days (an AltStore limitation, not
     this app's).

Free macOS runner minutes are generous for a public repo. A private repo has a
smaller monthly allowance, which is still plenty for occasional builds.

> Alternatives that also give you a cloud Mac build: **Codemagic** (free tier,
> has an iOS build machine) and **Xcode Cloud**. The same unsigned-build idea
> applies.

## Building on a Mac (if you get access to one)

You need **Xcode 16+** (iOS 17+ target, since the app uses SwiftData).

1. **Create the project.** In Xcode: *File ▸ New ▸ Project ▸ iOS ▸ App*.
   - Product name: `Cadence`
   - Interface: SwiftUI, Language: Swift
   - Storage: None (we configure SwiftData ourselves)
   - Uncheck tests if you like.
2. **Add the sources.** Delete the auto-generated `ContentView.swift` and the
   `@main` App file, then drag the `Cadence/` source folder from this repo into
   the project (choose "Copy items if needed" and create groups).
3. **Set the deployment target** to iOS 17.0 or later
   (*Project ▸ target ▸ General ▸ Minimum Deployments*).
4. **Signing.** In *Signing & Capabilities*, pick your Apple ID / development
   team. A free personal team works for sideloading to your own device (the
   signing certificate just expires every 7 days and needs a re-install).
5. **Run on device** — plug in your iPhone, select it as the run destination,
   and press ⌘R. For a free account you'll approve the developer profile once
   in *Settings ▸ General ▸ VPN & Device Management*.

### Making an .ipa for a sideloading tool (AltStore, Sideloadly, etc.)

1. Select *Any iOS Device (arm64)* as the destination.
2. *Product ▸ Archive*.
3. In the Organizer, *Distribute App ▸ Debugging* (or *Development*) ▸ export.
   That yields an `.ipa` you can hand to AltStore/Sideloadly.
   - Alternatively, for development signing, export without re-signing and feed
     the `.ipa` to your sideloading tool, which will re-sign with your account.

> Sideloading is for your own devices and development use. Keep it that way.

## Known simplifications (good first contributions)

- **Weekdays reminders** currently repeat daily at the fire time rather than
  skipping weekends (notification triggers can't express "weekdays only" in one
  request; schedule five weekday triggers to fix it).
- **No drag-to-reschedule yet** — editing the start time is done in the editor
  sheet. A drag gesture on `TimelineBlockView` that rounds to 5-minute steps is
  a natural next step.
- **No calendar (EventKit) import** — intentionally left out of v1 to keep the
  app free of system-calendar access. Could be added as an opt-in.
- **Overlapping items** stack at the same x-offset; a lane-layout algorithm
  would place concurrent items side by side.

## License

MIT — see [LICENSE](LICENSE).
