# Capability: Somatosensory Body Radar

## Overview
An interactive vector anatomical scanner that allows the user to visually locate and tap physical regions of nervous system distress.

## Requirements

### Requirement: Anatomical Node Mapping
The system SHALL render 6 interactive somatosensory nodes:
1. Cranial / Temples
2. Jaw / Cervical
3. Throat / Larynx
4. Thoracic / Cardiac
5. Solar Plexus / Gut
6. Extremities / Hands

#### Scenario: User taps cardiac node
- GIVEN the user is on the Somatosensory Body Radar
- WHEN they tap the chest region
- THEN the node pulsates with a bio-luminescent aura, fires light haptic feedback, and selects "Thoracic / Chest" in the underlying state.

### Requirement: Bio-Reactive Color Scaling
The radar halo color SHALL dynamically adapt to the nervous system arousal level:
- Low/Calm (1-3): Ice Sky Blue (#38BDF8)
- Grounded/Moderate (4-6): Warm Beige / Cashmere (#E7D8C9)
- High/Crisis (7-10): Striking Cherry Red (#E11D48)

