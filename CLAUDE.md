# Buddy — a PT app for kids

## What this is
An iPhone app physical therapists give to kid patients. The kid takes care of a puppy (a labrador named Buddy) that lives in the app, in the style of Talking Tom / Bubbu. Doing their PT exercises earns coins, and coins feed, bathe, rest and dress Buddy. Exercises use the iPhone camera to count reps and check form. This is a **demo build** that runs on sample data and has no real backend.

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
- For now, draw Buddy in SwiftUI shapes (head, ears, body, eyes that blink, tail that wags) with separate poses for idle, happy, eating, sleeping, bathing and demoing exercises, so Fiori can swap in real art later. Keep all of Buddy's drawing in `Buddy/Character/`.

## Screens
1. **Onboarding**: name, then PT code. Code `BUDDY123` loads the sample recovery plan. Show a friendly error for any other code.
2. **Home ("Buddy's house")**:
   - **To-do strip at the top**: today's exercises plus a "How's your knee?" check-in (emoji scale 1–5, Granola-style quick check-in)
   - Buddy in the middle of the room. Idles with small moves. Reacts when tapped (giggle, wiggle, bark), petted (drag) or poked.
   - Need bars: Hunger, Energy, Clean, Fun. These decay slowly over real time.
   - Bottom bar of round buttons: Kitchen, Bath, Bed, Closet, Shop, Exercises
   - Coin counter top right
3. **Kitchen**: swipe a food carousel (kibble, bone, apple, carrot, pupcake, ...), drag food to Buddy's mouth, eating animation, hunger bar fills
4. **Bath**: scrub with soap (drag), bubbles appear, rinse with shower button, Clean bar fills
5. **Bed**: tap the lamp so lights go off, Buddy sleeps (Zzz) and Energy fills over time
6. **Closet/Shop**: buy and equip hats, bandanas, glasses and toys with coins. Equipped items show on Buddy.
7. **Exercise session** (from the to-do list): Buddy demos the move, then a live camera view with a skeleton overlay, rep counter ("6 / 10 reps"), accuracy %, and spoken feedback. Finishing earns coins and stars, then a celebration screen.

## Demo exercises (pose tracking)
- **Arm raises (shoulder flexion)**: angle at the shoulder between hip, shoulder and wrist. A rep counts when it goes from <40° up to >150° and back. Cue "Reach higher!" if the peak is under 150°.
- **Mini squats**: knee angle between hip, knee and ankle. A rep counts when it goes from >160° down to <120° and back up. Cue "Bend a little more!" or "Not too low!" (<70°).
- Smooth the angles over the last ~5 frames. Ignore joints with confidence < 0.3. If key joints aren't visible, say "Step back so Buddy can see you."
- Accuracy = % of reps that hit the target range.

## Sample data
Seed `SampleData.swift` with patient "Maya", age 8, knee recovery, PT "Dr. Lee". Plan: Arm raises 2×10, Mini squats 2×8, daily check-in, reminders at 4:00 PM. Include a 2-week fake history so a "progress" view has something to show (adherence %).

## Working rules for Claude
- Build in the phases listed in PROMPTS.md. Do one phase at a time and stop for review.
- After every change, build with `xcodebuild` for the iOS Simulator and fix all errors before reporting done.
- Keep files small and organized: `App/`, `Models/`, `Screens/`, `Character/`, `Pose/`, `Components/`.
- Explain what you did in 3–5 plain sentences. Fiori is a designer, not an engineer.
