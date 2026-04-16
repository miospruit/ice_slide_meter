Openplanet plugins are written in AngelScript, the docs provide a standard plugin structure, NanoVG is the normal way to draw custom HUD overlays, the VehicleState dependency provides current vehicle telemetry, and Openplanet explicitly allows visual speed-drift and ice-slide indicator plugins on the plugin manager. ￼

Project goal

Build an Openplanet plugin for Trackmania that gives a live ice slide assist with three stages:
• V1: accurate telemetry meter
• V2: coaching/training overlay
• V3: short-horizon prediction / path helper

The key design choice is this: do not start with a path parabola. Start with a reliable signed slide angle and only add prediction after the core signal is trustworthy.

⸻

Final recommended structure

Start small:
• info.toml
• IceSlideAssist.as

Later, when it grows:
• info.toml
• Main.as
• Telemetry.as
• Math.as
• Hud.as
• Settings.as
• Predictor.as

For the first working version, one script file plus info.toml is enough.

⸻

Core concept

The plugin should derive an “ice slide angle” from telemetry rather than rely on a built-in single number.

Main metric

Compute the angle between:
• the direction the car is facing
• the direction the car is actually moving

That gives a slip / slide angle.

Best version of the metric

Use a signed angle so the plugin knows whether the car is sliding left or right.

Useful supporting values:
• speed
• lateral velocity
• yaw rate
• angle trend
• grounded / airborne state
• on-ice boolean
• confidence score

⸻

Shared technical foundations for all versions

1. Telemetry source

Use VehicleState as the main dependency for current vehicle data. The docs describe it as the source of current vehicle state information. ￼

2. Rendering

Use NanoVG for the HUD and lightweight overlays. The NanoVG tutorial is specifically about drawing plugin visuals. ￼

3. Plugin lifecycle

Use the standard Openplanet plugin structure and callbacks from the getting-started/plugin tutorials. ￼

4. Policy

This type of visual helper is allowed by Openplanet’s policy announcement on visual SD and ice-slide indicators. ￼

⸻

Core math

A. Basic vectors

Each frame, get or derive:
• car position
• car velocity
• car forward vector
• car right vector
• optionally local ground normal

B. Signed slide angle

For early versions, project onto a flat plane first.

Conceptually:
• forward = normalized(car forward projected onto plane)
• velDir = normalized(velocity projected onto plane)

Then compute:
• angle = atan2(signed_cross, dot)

A practical form is:
• dot = Dot(forward, velDir)
• cross = Cross(forward, velDir)
• angle = atan2(Dot(planeNormal, cross), dot)

That gives:
• negative angle = slide one side
• positive angle = slide the other side

C. Lateral slip

Also compute sideways speed:
• lateralSlip = Dot(velocity, rightVector)

This is useful because angle alone can look noisy at low speed.

D. Smoothing

Use light smoothing only:
• exponential smoothing, or
• rolling average over a few frames

E. Confidence score

Confidence should drop when:
• speed is low
• car is airborne
• contact is unstable
• the plugin is not certain it is on ice
• the signal is jittering

Use confidence to dim or suppress advanced visuals.

⸻

Plane handling strategy

This matters a lot.

Early implementation

Project vectors onto world-horizontal.

This is simpler and enough for first tests.

Better implementation

Project onto the local driving plane or ground plane.

This is more correct for:
• banking
• sloped ice
• transitions

Recommendation

Use horizontal projection in V1 if needed, then upgrade to local-plane projection once the core plugin works.

⸻

Ice detection strategy

Best case

Use contact or material data if available from the exposed state.

Fallback

If surface detection is hard, ship a debug mode first:
• always show meter
• manually toggle “ice-only”
• later auto-detect

Practical rule

Do not block the project on perfect ice detection. Build the angle engine first.

⸻

V1 — Telemetry meter

Goal

A compact and accurate live meter that shows what the car is doing right now.

Features
• signed slide angle
• speed
• lateral slip
• optional grounded indicator
• on-ice / not-on-ice state
• simple smoothing
• simple HUD bar

UI

Recommended V1 HUD:
• title: ICE
• numeric angle, like +27.4°
• centered bar from left to right
• zero marker in middle
• fill moving left/right with slide direction
• small speed readout
• dimmed state when airborne or not active

Frame loop

Each frame: 1. read vehicle state 2. check if player is driving 3. compute forward vector 4. compute velocity vector 5. project both onto chosen plane 6. compute signed angle 7. compute lateral slip 8. smooth values 9. render meter

V1 edge-case rules

Hide or dim the widget when:
• speed is too low
• velocity vector is too small
• car is airborne
• player is not in a valid run state

V1 settings
• enable/disable HUD
• minimum speed threshold
• smoothing strength
• HUD scale
• HUD position
• show numeric angle
• only show while driving
• debug mode

V1 success criteria

V1 is done when:
• left/right sign is correct
• angle changes immediately with slide changes
• it looks believable on known ice maps
• it is readable during play
• it has negligible performance impact

V1 expected complexity

About:
• 200–400 lines
• usually 2 files total if kept simple:
• info.toml
• one .as file

⸻

V2 — Training/coaching assist

Goal

Turn the raw telemetry into actionable driving feedback.

Features
• everything from V1
• target range / target band
• overslide vs underslide classification
• trend arrow
• recent history graph
• basic presets and settings
• optional training mode

Main new idea

Introduce a target model based on speed.

Example concept:
• lower speed allows wider angle
• higher speed prefers smaller angle

This should be implemented as a calibration table, not hardcoded “truth.”

Target model design

Use speed buckets:
• bucket speed
• target min angle
• target max angle

Then interpolate between buckets.

Example internal structure:
• 200 → 32–38
• 250 → 28–34
• 300 → 24–30
• 350 → 20–26

Those are starting calibration values, not guaranteed game constants.

Live classification

At runtime classify the current state as:
• optimal
• undersliding
• oversliding
• unstable
• inactive

Trend logic

Compute angle rate:
• current angle minus previous angle over delta time

Then show:
• increasing slide
• decreasing slide
• holding steady

History graph

Store a short ring buffer:
• timestamp
• speed
• angle
• lateral slip
• confidence
• on-ice

Draw a tiny graph of the last 0.5–1.5 seconds.

V2 UI

Recommended additions:
• green target band
• yellow warning margin
• red outside range
• small trend arrow
• small sparkline/history strip
• optional text like HOLD, OPENING, TOO WIDE

V2 settings

Add:
• target model preset
• target band opacity
• show history graph
• history duration
• show trend text
• hide outside ice
• compact mode

Calibration mode

Very useful in V2:
• record values while driving
• inspect angle ranges from successful slides
• use those values to tune presets

V2 success criteria

V2 is done when:
• players can actually react to the feedback
• the target band feels useful, not random
• the HUD stays readable
• the plugin still feels lightweight

V2 expected complexity

About:
• 400–800 lines
• often still manageable in a few files

⸻

V3 — Predictive helper / short path estimate

Goal

Give a short visual estimate of where the current slide is heading.

Important constraint

This must be treated as a short-horizon estimate, not exact future physics.

On ice, the future line changes quickly because of:
• steering changes
• contact changes
• walls
• slopes
• transitions
• airtime

So V3 should help intuition, not pretend to be perfect.

Features
• everything from V2
• projected short path
• uncertainty/confidence fade
• optional steering-response indicator
• optional path ribbon or arc

Recommended prediction methods

Option 1: simple kinematic predictor

Use current:
• position
• velocity
• heading
• yaw rate

Advance a few small time steps forward.

Pros:
• easiest
• cheap
• fast to build

Cons:
• less accurate when inputs change quickly

Option 2: recent-history curve fit

Use recent position samples to estimate local curvature, then extend it forward.

Pros:
• often smoother visually

Cons:
• can lag and still be wrong

Option 3: hybrid predictor

Blend:
• current velocity direction
• current slide angle
• current angle trend
• yaw rate
• short history curvature

This is the best long-term direction.

Recommended V3 implementation

Start with a hybrid-light version:
• prediction horizon: 0.3–0.8 seconds
• sample count: around 10–30 points
• fade the line as it goes forward
• reduce or hide prediction when confidence drops

Confidence use

Prediction should fade or disable when:
• airborne
• speed too low
• unstable contact
• not clearly on ice
• strong jitter
• recent sharp transition

V3 UI

Possible visuals:
• thin projected curve
• small ribbon showing likely spread
• green center if confidence high
• faint or dotted line if confidence low

V3 settings
• enable prediction
• prediction horizon
• sample count
• confidence threshold
• draw mode: line / ribbon / dots
• performance mode: low / medium / high

V3 success criteria

V3 is done when:
• the line helps more than it distracts
• it stays stable in sustained slides
• it fades or simplifies gracefully when uncertain
• FPS impact remains low

V3 expected complexity

About:
• 800+ lines
• code size depends mostly on polish and settings

⸻

Performance plan

V1

Tiny impact.

V2

Still tiny to small.

V3

Low to moderate if done properly.

What affects performance most

Not the angle math. Mostly:
• how much drawing happens each frame
• how many prediction samples are generated
• whether arrays/buffers are reused
• whether heavy logic runs only while needed

Performance safeguards
• only update prediction while driving
• skip predictor under low speed
• skip or fade when airborne
• keep the path horizon short
• reuse ring buffers
• avoid expensive visual effects
• add quality levels:
• low = meter only
• medium = meter + history
• high = meter + history + predictor

⸻

Development phases

Phase 0 — Research + debug shell

Build a tiny plugin that only proves data access.

Tasks:
• create plugin skeleton
• set up info.toml
• add VehicleState dependency
• draw a minimal debug window
• show speed and raw values

Deliverable:
• plugin loads and prints useful telemetry

Phase 1 — Math engine

Tasks:
• get forward vector
• get velocity vector
• project vectors to plane
• compute signed angle
• compute lateral slip
• add low-speed and airborne guards
• validate sign direction

Deliverable:
• correct live slide-angle number

Phase 2 — V1 HUD

Tasks:
• bar meter
• numeric angle
• smoothing
• thresholds
• HUD position/scale settings
• optional ice-only mode

Deliverable:
• usable V1 assist

Phase 3 — V2 coaching system

Tasks:
• target bands
• speed-based interpolation
• trend arrow
• history graph
• presets
• calibration mode

Deliverable:
• actual training overlay

Phase 4 — V3 predictor

Tasks:
• implement first predictor
• draw projected path
• add confidence logic
• compare prediction variants
• keep the one that feels best

Deliverable:
• short-horizon path assist

Phase 5 — Polish + packaging

Tasks:
• code split into files if needed
• reduce HUD clutter
• optimize update loop
• improve defaults
• add descriptions/settings text
• prepare plugin-manager release

⸻

Testing plan

Test environments

Use several map situations:
• straight sustained ice slide
• entry into ice
• exit from ice
• sloped ice
• banked ice
• mixed surfaces
• wall-near situations

What to validate

V1
• sign correctness
• responsiveness
• low jitter
• usable at speed

V2
• target bands feel plausible
• trend indicator is meaningful
• history graph is readable

V3
• projected path is stable
• it does not claim false precision
• it degrades well in uncertain states

⸻

Risks and mitigations

Risk: wrong angle basis

If the angle is computed on the wrong plane, it will mislead players.

Mitigation:
• start simple
• later add local-plane projection

Risk: poor ice detection

If the plugin cannot reliably detect ice, it may show at bad times.

Mitigation:
• add manual/debug mode first
• do not block the rest of development

Risk: too much UI clutter

A busy HUD becomes distracting.

Mitigation:
• compact defaults
• toggles for each feature
• quality presets

Risk: predictor looks precise but is not

The line could create false confidence.

Mitigation:
• short horizon only
• confidence fade
• never present it as exact

⸻

What is genuinely needed to build it

You need:
• Openplanet plugin scaffold
• info.toml
• AngelScript code
• VehicleState dependency
• NanoVG-based HUD drawing
• test maps with reliable ice sections
• calibration passes to tune target bands

These building blocks are directly aligned with Openplanet’s current docs and plugin system. ￼

⸻

Recommended final scope

Best MVP

Ship V1 first:
• signed angle
• lateral slip
• speed
• compact HUD
• smoothing
• optional ice-only mode

Best practical release

Then add V2:
• target range
• trend
• history
• presets

Best advanced version

Only then add V3:
• short-horizon predictor
• confidence fade
• lightweight rendering
