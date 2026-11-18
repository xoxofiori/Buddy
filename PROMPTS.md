# Buddy: copy-paste prompts for Claude Code

Paste one phase at a time. Before moving to the next phase, run the app (▶ in Xcode) and check it works.
If something looks off, just describe it or drop in a screenshot: "Buddy's ears look like triangles, make them floppy."

---

## Phase 1: Skeleton + onboarding
Read CLAUDE.md. Set up the folder structure, the color palette and rounded font, the GameState model with JSON saving, and SampleData (Maya's plan). Build the onboarding flow: name, then PT code (BUDDY123 works), then a placeholder home screen that says "Hi Maya!". Build for the simulator and fix any errors.

## Phase 2: Buddy + his house
Build Buddy as an original cartoon labrador in SwiftUI shapes with idle, happy, eating, sleeping and bathing poses (blinking eyes, wagging tail). Build the home screen: room background, to-do strip at the top, need bars, coin counter, and the bottom button bar. Buddy reacts to taps and petting. Need bars slowly decay over real time.

## Phase 3: Care rooms
Build the Kitchen (food carousel, drag food to Buddy, eating animation), Bath (drag soap, bubbles, shower rinse), and Bed (lamp off, Buddy sleeps, energy refills). Each one costs or uses coins/items and fills its need bar.

## Phase 4: Shop + closet
Build the Shop and Closet: hats, bandanas, glasses and toys bought with coins and shown on Buddy when equipped. Give Maya 50 starter coins.

## Phase 5: Exercise camera (the core PT feature)
Build the exercise session: Buddy demos the move, then a front-camera view with a skeleton overlay using Apple Vision body pose. Implement rep counting and form cues for Arm Raises and Mini Squats exactly as in CLAUDE.md, plus spoken feedback, a rep counter and accuracy %. Finishing awards coins and marks the to-do done, then a celebration screen. Add the camera permission text to Info.plist: "Buddy uses the camera to count your exercise reps. Video never leaves your phone."

## Phase 6: Check-in + progress + polish
Add the "How's your knee?" emoji check-in and a simple progress screen (streak, adherence %, reps over the past 2 weeks). Then polish: sounds/haptics on every tap, spring animations, an app icon placeholder, and a reset-demo button in a hidden settings menu.

## Phase 7: Ready for TestFlight
Set the bundle ID to com.fiorilee.buddy, version 1.0, build 1. Check that all Info.plist permission strings exist, there are no warnings that would block upload, and the app runs on a real iPhone. Tell me the exact steps to Archive and upload in Xcode.
