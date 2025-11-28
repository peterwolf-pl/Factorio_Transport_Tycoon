data:extend({
  { type = "int-setting", name = "sbt-contract-duration-min", setting_type = "runtime-global", default_value = 10, minimum_value = 2, maximum_value = 120 },
  { type = "bool-setting", name = "sbt-hostile-waves", setting_type = "runtime-global", default_value = false },
   {
    type = "int-setting",
    name = "ftt-exchange-choc-to-alc-input",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 100000,
    order = "a[exchange]-a[choc-to-alc-input]"
  },
  {
    type = "int-setting",
    name = "ftt-exchange-choc-to-alc-output",
    setting_type = "runtime-global",
    default_value = 100,
    minimum_value = 1,
    maximum_value = 100000,
    order = "a[exchange]-b[choc-to-alc-output]"
  },
  {
    type = "int-setting",
    name = "ftt-exchange-alc-to-choc-input",
    setting_type = "runtime-global",
    default_value = 10,
    minimum_value = 1,
    maximum_value = 100000,
    order = "b[exchange]-a[alc-to-choc-input]"
  },
  {
    type = "int-setting",
    name = "ftt-exchange-alc-to-choc-output",
    setting_type = "runtime-global",
    default_value = 100,
    minimum_value = 1,
    maximum_value = 100000,
    order = "b[exchange]-b[alc-to-choc-output]"
  },
    {
    type = "int-setting",
    name = "ftt-offer-generosity",
    setting_type = "runtime-global",
    default_value = 3,
    minimum_value = 1,
    maximum_value = 10,
    order = "c[offers]-a[generosity]"
  }
})