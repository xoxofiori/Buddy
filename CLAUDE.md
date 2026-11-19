# Buddy — a PT app for kids

## What this is
An iPhone app physical therapists give to kid patients. The kid takes care of a puppy (a labrador named Buddy) that lives in the app, in the style of Talking Tom / Bubbu. Doing their PT exercises earns bones, and kids look after Buddy (feed, bathe, nap, play, dress up) in his backyard. Exercises use the iPhone camera to count reps and check form. This is a **demo build** that runs on sample data and has no real backend.

## Stack (keep it this simple)
- SwiftUI, iOS 17+, iPhone only, portrait only
- Apple **Vision** (`VNDetectHumanBodyPoseRequest`) + **AVFoundation** front camera for pose tracking
- Persistence: a single `Codable` game-state struct saved as JSON to the app's documents folder
- Sounds/speech: `AVSpeechSynthesizer` for spoken praise/corrections
- **No third-party packages.** Everything is built in.
- Bundle ID: `com.fiorilee.buddy`

## Design rules
- Palette ("soft, sunny, never neon"): Sky `#5DB6E8`, Sprout `#B5DD7A`, Coral `#E8765A`, Sunny `#FFB547`, Lavender `#D9D2F2`, Cream `#FFF6E5`, Paper `#FFFDF8`, Deep Teal `#24403E` (dark text/buttons)
- Font: SF Rounded (`.fontDesign(.rounded)`), chunky weights, big text
- Big tap targets (min 60pt) for small hands. Every action has bouncy spring animations and a sound or haptic.
- Feedback copy is always encouraging. Never say "wrong." Examples: "Great bend! Keep going!", "Almost! Go a little lower.", "Step back so Buddy can see your knees."
- Buddy is an **original** cartoon labrador (golden, floppy ears, round and friendly). Don't copy Talking Tom's artwork, name or sounds, but use Tom as the reference for how human-like Buddy should be. Buddy stands upright on two legs, has arms and hands, and has an expressive, almost human face (big eyes, eyebrows, a mouth that smiles, talks and yawns). He moves like a person, so he can demo exercises the way a kid would do them: raising his arms, squatting, and so on.
- **Buddy is built from Fiori's art, not drawn in code.** Follow `BuddyCharacter/CHARACTER.md` exactly: the PDF parts in `Assets.xcassets` (Preserve Vector Data, single scale) are stacked in `Buddy/Character/BuddyView.swift` and only rotated, scaled or swapped (layer order, pivots, poses, blink, breathing, tail). Never redraw or offset parts. Poses: idle, talking, waving, armRaise, sleeping, needsCare, squat, plus eating and happy (made from the same parts) for the care rooms.
- **The UI follows `BuddyCharacter/UI_DIRECTION.md`**: Talking Tom is a reference for feel only. Soft storybook style (flat colors, gentle gradients, paper-cut shapes, paper texture), not glossy 3D.

## Screens
1. **Onboarding**: name, then PT code. Code `BUDDY123` loads the sample recovery plan. Show a friendly error for any other code.
2. **Home ("Buddy's Backyard")**: one illustrated scene, no bottom button bar.
   - **"Today with Buddy" card at the top**: big tiles for each exercise (mini Buddy doing the move, reps, "Let's go") plus the "How's your knee?" check-in. Done tiles flip to a sticker.
   - **Check-in**: the kid rates knee pain 1–10 (faces, green → coral). Buddy's face mirrors the answer; for 7+ he kindly asks them to tell a grown-up or Dr. Lee. Saved per day (+2 bones the first time each day).
   - **Recovery Trail / progress** (map icon + arch on the garden path): streak (days in a row with an exercise), adherence % over 2 weeks, reps per day chart, and the knee-pain trend.
   - Buddy stands on the garden path. Tap head (giggle, ears flop), tap belly (squash bounce), drag to pet (hearts).
   - **Care by tapping things in the yard**: food bowl → feed, kiddie pool → bath, doghouse → nap, toy box → shop, arch on the garden path → Recovery Trail. A thing bobs when its need is low.
   - When a need runs low Buddy shows it: **hungry** (fed < 30%) he holds and rubs his tummy with a sad face; **muddy** (clean < 50%) he has mud spots (the same ones the bath scrubs). A tappable "Hungry" / "Muddy" thought bubble opens Snack time / Bath time, and every ~20 s he says what he needs. Grown-up settings have "Make hungry" / "Make muddy" for demos.
   - Needs (fed, clean, rested, played) decay slowly over real time and show as **one heart on Buddy's collar tag** that fills in sections. Tap the tag for details.
   - **Bones** counter top right (the currency).
   - Sky follows the real clock: morning, day, sunset, night (stars, fireflies, Buddy dozes). The time-of-day color wash tints only the sky, grass and fence; Buddy, the tappable yard objects and their icons stay fully bright at every time of day. Hold "Hi Maya!" for 1.5 s to open the hidden grown-up settings: patient/plan info, sound effects and voice switches, time-of-day preview, and **Reset demo**.
   - **Hidden demo menu**: tap the bones counter for **Reset today** (keeps the kid, bones and outfit; clears today's to-dos, check-in and today's history line) and **Start over** (asks first, then clears the saved game and returns to onboarding). The launch argument **`-resetDemo`** does the same as Start over on startup.
   - Every button gives a soft click and a light haptic (`SquishStyle` + `Feedback`); tapping a yard object *or its floating icon* opens its screen.
   - Every yard object that opens a screen has a small floating icon badge above it, so kids know to tap it.
   - **Basic care is always free** (kibble, plain soap, naps) so a kid is never stuck; treats and rainbow soap cost bones.
3. **Food bowl ("Snack time")**: swipe a food carousel (kibble, bone, apple, carrot, pupcake, ...), drag food to Buddy's mouth, the "fed" heart section fills
4. **Pool ("Bath time")**: scrub with soap (drag), bubbles appear, rinse, the "clean" section fills
5. **Doghouse ("Nap time")**: tap the lamp to turn off the lights, tuck Buddy in, he sleeps (Zzz) and the "rested" section fills over time
6. **Shop (toy box)**: buy and equip hats, bandanas, glasses and toys with bones, all in one place (there is no separate Closet). Equipped items show on Buddy.
7. **Exercise session** (from the to-do list): Buddy demos the move, then a live camera view with a skeleton overlay, rep counter ("6 / 10 reps"), accuracy %, and spoken feedback. Finishing earns bones (golden bones for perfect form) and stars, then a celebration screen. See UI_DIRECTION.md §5 for the side-by-side layout.

## Demo exercises (pose tracking)
- **Arm raises (shoulder flexion)**: angle at the shoulder between hip, shoulder and wrist. A rep counts when it goes from <40° up to >150° and back. Cue "Reach higher!" if the peak is under 150°.
- **Mini squats**: knee angle between hip, knee and ankle. A rep counts when it goes from >160° down to <120° and back up. Cue "Bend a little more!" or "Not too low!" (<70°).
- Smooth the angles over the last ~5 frames. Ignore joints with confidence < 0.3. If key joints aren't visible, say "Step back so Buddy can see you."
- Accuracy = % of reps that hit the target range. A try that stops short (arm raise peak under 150°, squat not below 120°) gets its cue and counts as a try but not a rep; a squat below 70° counts as a rep but is off target. So accuracy = on-target reps ÷ all tries.
- Each rep earns a bone; each on-target rep is a golden bone (worth 2). Finishing marks the exercise done on today's card and updates today's history line.
- Devices without a front camera (the Simulator) and kids without camera permission get **practice mode**: a pretend skeleton does the reps (with a few short and too-deep ones) through the same counting code.

## Sample data
Seed `SampleData.swift` with patient "Maya", age 8, knee recovery, PT "Dr. Lee". Plan: Arm raises 2×10, Mini squats 2×8, daily check-in, reminders at 4:00 PM. Include a 2-week fake history so a "progress" view has something to show (adherence %).

## Working rules for Claude
- Build in the phases listed in PROMPTS.md. Do one phase at a time and stop for review.
- After every change, build with `xcodebuild` for the iOS Simulator and fix all errors before reporting done.
- Keep files small and organized: `App/`, `Models/`, `Screens/`, `Character/`, `Pose/`, `Components/`.
- Explain what you did in 3–5 plain sentences. Fiori is a designer, not an engineer.
