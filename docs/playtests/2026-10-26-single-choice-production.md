# Single-choice production

Factories now start their sole recipe directly when the output action box or its output inventory is tapped. No one-choice popup is constructed. Repeated taps preserve the active batch, progress and input reservation.

Menus remain only when useful controls are available: a supported Waterwheel queue action, or the existing Scout/Bait/Select controls for owned equipment. The queue runtime and UI share supports_queue eligibility. The menu is rebuilt when its control set changes; retired menu buttons are removed from the tracked control list. Recipes, costs, timing and output amounts are unchanged.

production_converter.gd passed real-main mouse/touch checks across all nine converters, including direct start, no popup, repeat-tap preservation, output-inventory taps, actual queue enqueue and owned equipment controls. Raw 1080x1920 proof: outputs/verification/one-tap-factories-oct26/melt-sand-one-tap.png and shape-bottles-one-tap.png. All tests used isolated storage, disabled save writes/online requests and muted audio.

Production-path and detailed inventory/payment regressions were also run. No Android export, phone install or external publication was requested or performed.
