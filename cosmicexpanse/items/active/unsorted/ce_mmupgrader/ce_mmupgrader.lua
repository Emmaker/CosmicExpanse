require "/scripts/util.lua"

function activate(fireMode, shiftHeld)
  item.consume(1)

  local slot = config.getParameter("essentialSlot", "beamaxe")
  local item = player.essentialItem(slot)
  util.mergeTable(item.parameters, config.getParameter("upgrades"))
  sb.logInfo("item: %s", item)
  player.giveEssentialItem(slot, item)
end