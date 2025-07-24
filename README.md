# Sound Muffling Effect

## About
Have you ever thought how odd it is that sounds do not seem to care about walls? Why do gunshots behind 3 meters of concrete sound the same as when it's they go off right in front of you? This addon was created to address those issues.

## Features
- Dynamically determine the appropriate muffling effect using a sensible occlusion detection.
- Three muffle effect variant. One for each distance range.
- Distant muffling for things that are far away regardless of obstruction.
- Customisation via console variables.
- Works for every sound other than voice chat as far as I know.
- Multiplayer compatible. Each player will hear different muffling levels based on their position.

## Commands

- **sme_active** (serverside) - Enable or disable sound muffling.
- **sme_attenuation** - Enable or disable custom attenuation. Disable this if you think sound radii are too low.
- **sme_sound_bouncing** - Enable or disable sound bouncing. You can turn this off if you're experiencing performance problems. Note that this makes sound muffling way less accurate.
- **sme_sound_launch_dist** - Part of sound bouncing. How far can a sound launch from a source before it starts bouncing.
- **sme_min_thickness** - How much distance between you and where a sound source hit a solid for muffling effect to apply. Increase if you think sounds get muffled too easily. Decrease if you think that sounds hardly gets muffled. Setting it to 0 effectively disables it.
- **sme_far_muffle_dist** - How far away should a sound be for it to be muffled regardless of occlusion. Setting it to 0 effectively disables it.