-- prototypes/technologies.lua

local MOD = "__factorio-transport-tycoon__"

data:extend({
  {
    type = "technology",
    name = "sbt-bug-trade",
    icon = MOD .. "/graphics/icons/credit.png",
    icon_size = 64,
    effects = {
      { type = "unlock-recipe", recipe = "sbt-chocolate" },
      { type = "unlock-recipe", recipe = "sbt-alcohol" }
    },
    unit = {
      count = 1,
      ingredients = {
        {"automation-science-pack", 1}
      },
      time = 15
    },
    prerequisites = {}
  }
})
