# V1 Test Checklist

Use this checklist during manual validation.

## Test environments

- Straight sustained ice slide
- Entry into ice from non-ice surface
- Exit from ice to non-ice surface
- Sloped ice
- Banked ice
- Mixed surface transitions
- Wall-near and correction scenarios

## Pass criteria by signal

### Signed angle

- Left slide shows consistent sign
- Right slide shows opposite sign
- Sign does not flicker during stable slide

### Responsiveness

- Fast transitions reflect on HUD quickly
- No obvious lag from smoothing defaults

### Stability guards

- Meter dims/hides below minimum speed
- Meter dims/hides while airborne
- Meter dims/hides when not in valid driving state

### Readability

- Numeric angle readable at race pace
- Bar center and direction are clear
- Widget does not obstruct key game view

### Performance

- No noticeable frame drops during normal runs

## Logging notes

Record for each map:

- map name
- test scenario
- observed behavior
- pass/fail
- tuning changes (if any)
