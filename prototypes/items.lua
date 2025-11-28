local MOD = "__factorio-transport-tycoon__"
local function icon(f) return MOD .. "/graphics/icons/" .. f end

data:extend({
  {
    type = "item",
    name = "sbt-chocolate",
    icon = icon("chocolate.png"),
    icon_size = 64,
    stack_size = 100,
    subgroup = "intermediate-product",
    order = "sbt-a[chocolate]"
  },
  {
    type = "item",
    name = "sbt-alcohol",
    icon = icon("alcohol.png"),
    icon_size = 64,
    stack_size = 100,
    subgroup = "intermediate-product",
    order = "sbt-b[alcohol]"
  },
  {
    type = "item",
    name = "sbt-cargo-rover",
    icon = icon("rover.png"),
    icon_size = 64,
    place_result = "sbt-cargo-rover",
    stack_size = 1,
    subgroup = "transport",
    order = "sbt-c[rover]"
  }
})
