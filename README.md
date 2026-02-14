# Hand Gesture Knob Turning Template

Hand-gesture-driven 3D knob rotation for visionOS. The user rotates their left wrist clockwise to turn a 3D knob through a full 360-degree rotation on Apple Vision Pro.

---

## Setup

1. Add the three Swift files to your visionOS Xcode project.
2. Add your `.usdz` knob model to the project bundle.
3. Open `KnobRotationView.swift` and replace `"KnobAsset"` with your filename (without the `.usdz` extension).
4. Add the hand tracking usage description to your `Info.plist`:

```xml
<key>NSHandsTrackingUsageDescription</key>
<string>This app uses hand tracking to control a 3D knob rotation.</string>
```

5. Build and run on Apple Vision Pro or the visionOS Simulator.

If no asset is provided, a placeholder cylinder will appear so you can test the gesture immediately.

---

## Files

| File | Purpose |
|------|---------|
| `KnobRotationApp.swift` | App entry point. Opens a mixed immersive space. |
| `HandGestureKnobController.swift` | Tracks left hand rotation and outputs a 0.0 to 1.0 value. |
| `KnobRotationView.swift` | Loads a 3D knob and applies rotation from the controller. |

---

## How It Works

The controller reads the angle between the thumb knuckle and wrist joints on the left hand. As the wrist rotates clockwise, the value moves from 0.0 (hand upright) to 1.0 (hand fully rotated). That value is mapped to 0 through 360 degrees of rotation on the 3D knob entity.

---

## What to Change

Each item below corresponds to a labeled comment in the source code (e.g., "see README Section 1"). All changes are optional.

### Section 1 -- Asset Name

**File:** `KnobRotationView.swift`
**Line:** `let knob = await loadKnobEntity(named: "KnobAsset")`

Replace `"KnobAsset"` with the filename of your `.usdz` model, without the extension. The file must be in your Xcode project bundle. If you load assets from a remote URL or a `.reality` file, replace the `loadKnobEntity(named:)` method with your own loading logic.

### Section 2 -- Knob Position and Scale

**File:** `KnobRotationView.swift`

```swift
private let knobPosition = SIMD3<Float>(0, 1.2, -0.8)
private let knobScale: Float = 0.15
```

- `knobPosition` -- placement in meters. X = left/right, Y = up/down, Z = forward/backward (negative values are in front of the user).
- `knobScale` -- uniform scale factor. Adjust to fit your model's native size.

### Section 3 -- Angle Mapping (Sensitivity)

**File:** `HandGestureKnobController.swift`

```swift
private let startAngle: Float = 90.0
private let endAngle: Float = 32.0
```

These define the physical wrist rotation range that maps to a full 360-degree knob turn. The comfortable human wrist range is roughly 60 degrees, so the full knob rotation is mapped to that smaller physical range.

- `startAngle` (default 90) -- wrist angle in degrees where rotation = 0.0 (hand upright, thumb at 12 o'clock).
- `endAngle` (default 32) -- wrist angle in degrees where rotation = 1.0 (hand rotated clockwise).
- To make rotation slower (finer control), decrease `endAngle` to widen the range.
- To make rotation faster, increase `endAngle` to narrow the range.

### Section 4 -- Tracked Hand

**File:** `HandGestureKnobController.swift`

```swift
private let trackedChirality: HandAnchor.Chirality = .left
```

Change to `.right` to track the right hand instead.

### Section 5 -- Smoothing

**File:** `HandGestureKnobController.swift`

```swift
private let bufferSize = 5
private let minChangeThreshold: Float = 0.005
```

- `bufferSize` -- number of frames averaged together. Higher values produce smoother output but add input lag. Recommended range: 3 to 10.
- `minChangeThreshold` -- minimum change required to fire the callback. Increase this if you see flickering.

### Section 6 -- Tracked Joints

**File:** `HandGestureKnobController.swift`, inside `processHandAnchor(_:)`

```swift
guard let thumbKnuckle = anchor.handSkeleton?.joint(.thumbKnuckle),
      let wrist = anchor.handSkeleton?.joint(.wrist) else {
```

You can substitute other joint pairs if a different gesture feels more natural. For example, `.middleFingerKnuckle` and `.wrist`.

### Section 7 -- Rotation Axis

**File:** `KnobRotationView.swift`

```swift
private let rotationAxis = SIMD3<Float>(0, 1, 0)
```

- `[0, 1, 0]` -- Y-axis. Turntable or dial rotation, viewed from above.
- `[0, 0, 1]` -- Z-axis. Clock-face rotation, viewed head-on.
- `[1, 0, 0]` -- X-axis. Tilt rotation.

### Section 8 -- Rotation Direction

**File:** `KnobRotationView.swift`, inside the `update` closure.

```swift
let fullRotationRadians = rotationValue * 2.0 * .pi
```

Negate the value (`-rotationValue * 2.0 * .pi`) to reverse the rotation direction.

### Section 9 -- Debug HUD

**File:** `KnobRotationView.swift`, the `Attachment(id: "rotationLabel")` block.

This displays a floating panel showing the current rotation in degrees and a circular progress indicator. Remove the entire `Attachment` block and its corresponding `attachments.entity(for: "rotationLabel")` references if you do not need it.

---

## Integrating Into an Existing Project

If you already have a visionOS app:

1. Copy `HandGestureKnobController.swift` and `KnobRotationView.swift` into your project. You do not need `KnobRotationApp.swift`.
2. Present `KnobRotationView` inside your own `ImmersiveSpace`, or use `HandGestureKnobController` directly in your existing `RealityView` by listening to `onRotationValueChanged`.

---

## Requirements

- Xcode 26 or later
- visionOS 2.0+
- Apple Vision Pro or visionOS Simulator
- ARKit hand tracking entitlement
