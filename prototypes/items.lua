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
  }
})
