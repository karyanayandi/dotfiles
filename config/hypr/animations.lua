-- ~/.config/hypr/animations.lua

-- Critically damped: quick settle without decorative bounce.
hl.curve("appleSpring", { type = "spring", mass = 1, stiffness = 180, dampening = 27 })
hl.curve("easeOut", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })

hl.animation { leaf = "global", enabled = true, speed = 3, bezier = "easeOut" }

hl.animation { leaf = "border", enabled = true, speed = 2, bezier = "easeOut" }

hl.animation { leaf = "windows", enabled = true, speed = 4, spring = "appleSpring" }
hl.animation { leaf = "windowsIn", enabled = true, speed = 4, spring = "appleSpring", style = "popin 94%" }
hl.animation { leaf = "windowsOut", enabled = true, speed = 3, spring = "appleSpring", style = "popin 94%" }
hl.animation { leaf = "windowsMove", enabled = true, speed = 4, spring = "appleSpring" }

hl.animation { leaf = "fade", enabled = true, speed = 2, bezier = "easeOut" }
hl.animation { leaf = "fadeOut", enabled = true, speed = 1.5, bezier = "easeOut" }

hl.animation { leaf = "layers", enabled = true, speed = 2.5, bezier = "easeOut", style = "fade" }
hl.animation { leaf = "layersOut", enabled = true, speed = 2, bezier = "easeOut", style = "fade" }

hl.animation { leaf = "workspaces", enabled = true, speed = 3.5, spring = "appleSpring", style = "slidefade 12%" }
hl.animation { leaf = "zoomFactor", enabled = true, speed = 3, bezier = "easeOut" }
hl.animation { leaf = "borderangle", enabled = false }
