require "/scripts/util.lua"

function init()
  self.upgrades = config.getParameter("upgrades")
  self.swingTime = config.getParameter("swingTime")
  activeItem.setArmAngle(-math.pi / 2)
end

function update(dt, fireMode, shiftHeld)
  updateAim()

  if not self.swingTimer and fireMode == "primary" and player then
    self.swingTimer = self.swingTime
  end

  if self.swingTimer then
    self.swingTimer = math.max(0, self.swingTimer - dt)

    activeItem.setArmAngle((-math.pi / 2) * (self.swingTimer / self.swingTime))

    if self.swingTimer == 0 and not self.doOnce then
      self.doOnce = true
      upgradeMM()
    end
  end
end

function upgradeMM()
  local slot = config.getParameter("essentialSlot", "beamaxe")
  local slotItem = player.essentialItem(slot)
  util.mergeTable(slotItem.parameters, self.upgrades)
  player.giveEssentialItem(slot, slotItem)

  interface.queueMessage("Matter Manipulator upgraded!", 4, 0.5)

  item.consume(1)
end

function updateAim()
  self.aimAngle, self.aimDirection = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  activeItem.setFacingDirection(self.aimDirection)
end