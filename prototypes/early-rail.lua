-- prototypes/early-rail.lua

-- Proste przepisy tylko z iron-plate
-- Klucz: nazwa przepisu
-- Wartość: liczba iron-plate jako koszt
local simple_iron_recipes = {
  ["rail"] = 2,           -- koszt za standardowy wynik recipe
  ["train-stop"] = 10,
  ["rail-signal"] = 5,
  ["rail-chain-signal"] = 5,
  ["locomotive"] = 20,
  ["cargo-wagon"] = 14
}

local function apply_simple_iron_recipe(name, iron_cost)
  local r = data.raw.recipe[name]
  if not r then
    return
  end

  -- Wymuś odblokowanie od startu
  local function set_def(def)
    if not def then
      return
    end
    def.enabled = true
    def.ingredients = {
      {type = "item", name = "iron-plate", amount = iron_cost}
    }
  end

  if r.normal or r.expensive then
    -- Styl z normal/expensive
    if r.normal then
      set_def(r.normal)
    end
    if r.expensive then
      set_def(r.expensive)
    end
  else
    -- Prosty styl
    r.enabled = true
    r.ingredients = {
      {type = "item", name = "iron-plate", amount = iron_cost}
    }
  end
end

for name, cost in pairs(simple_iron_recipes) do
  apply_simple_iron_recipe(name, cost)
end