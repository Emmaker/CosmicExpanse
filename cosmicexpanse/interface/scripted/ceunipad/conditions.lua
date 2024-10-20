conditions = conditions or { }
function condition(id, ...) return conditions[id] and conditions[id](...) end

conditions["not"] = function(...)
  return not condition(...)
end

function conditions.any(...)
  for _, c in pairs{ ... } do
    if condition(table.unpack(c)) then return true end
  end
  return false
end

function conditions.all(...)
  for _, c in pairs{ ... } do
    if not condition(table.unpack(c)) then return false end
  end
  return true
end

function conditions.admin()
  return player.isAdmin()
end

function conditions.statPositive(stat)
  return status.statPositive(stat)
end

function conditions.statNegative(stat)
  return not status.statPositive(stat)
end

function conditions.species(species)
  return player.species() == species
end

function conditions.ownShip()
  return player.worldId() == player.ownShipWorldId()
end

function conditions.hasCompletedQuest(questId)
  return player.hasCompletedQuest(questId)
end

function conditions.configExists(key)
  return pcall(function() root.assetJson(key) end)
end

function conditions.techExists(name)
  return root.hasTech(name)
end

function conditions.recipe(name)
  return player.isAdmin() or player.bluePrintKnown({ name = name, count = 1 })
end

function conditions.hasFlaggedItem(flag, value)
  return player.hasItemWithParameter(flag, value or true)
end

function conditions.hasTaggedItem(tag, count)
  local c = player.inventoryTags()[tag] or 0
  return c  >= (count or 1)
end

function conditions.exec(script, ...)
  if type(script) ~= "string" then return end
  params = { ... }
  _SBLOADED[script] = nil require(script)
  params = nil

  return type(bool) == "boolean" and bool
end