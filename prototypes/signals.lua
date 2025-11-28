-- prototypes/signals.lua
local MOD = "__factorio-transport-tycoon__"

data:extend({
  {
    type = "virtual-signal",
    name = "sbt-credits",
    icon = MOD .. "/graphics/icons/credit.png",
    icon_size = 64,
    subgroup = "virtual-signal-number",
    order = "z[sbt]-a[credits]"
  }
})
