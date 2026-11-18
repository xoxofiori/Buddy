# Buddy character: implementation spec

Replace any code-drawn version of Buddy with these art files. **Do not redraw Buddy in SwiftUI shapes.** Only animate these parts.

## Files
- `pdf/`: use these in Xcode (most reliable vector format)
- `svg/`: source files (same art)
- `buddy_pose_sheet.png`: reference for how every pose should look

Every part sits on the **same 600 × 800 canvas**, already positioned. Stack them in a `ZStack` at the same frame and they line up perfectly. Never offset parts to "fix" alignment.

## Setup
1. Add every PDF in `pdf/` to `Assets.xcassets` as an Image Set with the same name (`buddy_head`, etc.). Turn on **Preserve Vector Data** and set Scales to **Single Scale**.
2. Create `Character/BuddyView.swift`: a `ZStack` of `Image("...").resizable()` parts inside `.aspectRatio(600/800, contentMode: .fit)`.
3. Drive it from a `BuddyMood` / `BuddyPose` enum, so other screens just say `BuddyView(pose: .sleeping)`.

## Layer order (back → front)
1. `buddy_shadow`
2. `buddy_tail`
3. `buddy_leg_left`, `buddy_leg_right`
4. `buddy_body`
5. **Head group** (rotates and bobs together): `buddy_head`, `buddy_ear_left`, `buddy_ear_right`, one `buddy_eyes_*`, one `buddy_brows*`, one `buddy_mouth_*`
6. `buddy_arm_left`, `buddy_arm_right`

## Pivot points (use as `rotationEffect` anchors; UnitPoint = x/600, y/800)
| Part | Canvas point | UnitPoint |
|---|---|---|
| Head group (neck) | (300, 372) | (0.500, 0.465) |
| Left ear | (190, 138) | (0.317, 0.173) |
| Right ear | (410, 138) | (0.683, 0.173) |
| Left arm (shoulder) | (226, 428) | (0.377, 0.535) |
| Right arm (shoulder) | (374, 428) | (0.623, 0.535) |
| Tail base | (378, 562) | (0.630, 0.703) |

Positive degrees = clockwise. Resting arms are at left **+6°** and right **−6°**.

## Poses (match buddy_pose_sheet.png)
| Pose | Eyes | Brows | Mouth | Arms L / R | Head | Ears L / R | Tail |
|---|---|---|---|---|---|---|---|
| idle | open | brows | smile | 6 / −6 | 0 | 0 / 0 | 0 |
| talking | open | brows | alternate open ↔ smile every 0.12 s | 6 / −6 | −6 | −6 / 4 | −12 |
| waving | happy | brows | open | 6 / −128 ± 12 wiggle | 5 | 0 / 0 | 10 |
| armRaise (exercise demo) | happy | brows | open | animate 6 → 118 / −6 → −118 | 0 | 0 / 0 | −10 |
| sleeping | closed | brows | o | 6 / −6 | 10 | 10 / −10 | 0 |
| needsCare | open | brows_worried | o | 6 / −6 | −4 | 0 / 0 | 0 |
| squat demo | open | brows | open | 40 / −40 (arms forward-ish) | 0 | 0 / 0 | 0 |

For the squat, move the whole character down 40 pt and squash the legs with scaleY 0.75 (anchor at the feet).

## Always-on life (so he never looks frozen)
- **Breathing:** body + head group scale 1.0 → 1.015 vertically, 2.4 s ease in-out, forever (slower when sleeping)
- **Blink:** every 3–6 s (random), swap to `eyes_closed` for 0.12 s
- **Tail:** gentle ±6° sway, 1.2 s. Fast ±15° wag at 0.25 s when happy.
- **Idle fidget:** every 8–15 s, do a small head tilt (±5°) or an ear flick (±8°)

## Interactions
- Tap head: ears flop ±12° with a spring, `eyes_happy`, giggle sound
- Tap belly: squash-and-stretch bounce (scale 0.95 → 1.05 → 1), `mouth_open`
- Drag across him (petting): `eyes_happy`, fast tail wag while dragging
- All transitions use springs (response ~0.35, damping ~0.6). Nothing should snap.
