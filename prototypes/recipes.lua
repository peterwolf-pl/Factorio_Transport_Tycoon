-- prototypes/recipes.lua

data:extend({
  {
    type = "recipe",
    name = "sbt-chocolate",
    enabled = true,
    energy_required = 2,
    category = "crafting",
    ingredients = {
      {type = "item", name = "wood", amount = 2}
    },
    results = {
      {type = "item", name = "sbt-chocolate", amount = 1}
    },
    allow_as_intermediate = true,
    allow_decomposition = true
  },
  {
    type = "recipe",
    name = "sbt-alcohol",
    enabled = true,
    energy_required = 4,
    category = "crafting-with-fluid",
    ingredients = {
      {type = "fluid", name = "water", amount = 50},
      {type = "item",  name = "wood",  amount = 5}
    },
    results = {
      {type = "item", name = "sbt-alcohol", amount = 1}
    },
    allow_as_intermediate = true,
    allow_decomposition = true
  }
})
