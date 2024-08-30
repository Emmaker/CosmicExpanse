require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/portraits.lua"

function init()
  storage.complete = storage.complete or false
  self.compassUpdate = config.getParameter("compassUpdate", 0.5)
  self.descriptions = config.getParameter("descriptions")

  self.medicalItem = config.getParameter("medicalItem")

  self.ingredient1 = config.getParameter("ingredient1")
  self.ingredient1Count = config.getParameter("ingredient1Count")
  self.ingredient2 = config.getParameter("ingredient2")
  self.ingredient2Count = config.getParameter("ingredient2Count")

  self.medicineItem = config.getParameter("medicineItem")

  self.tutorialUid = config.getParameter("tutorialUid")

  setPortraits()

  storage.stage = storage.stage or 1
  self.stages = {
    craftMedical,
    collectIngredient1,
    collectIngredient2,
    craftMedicine,
    returnTutorial
  }

  self.state = FSM:new()
  self.state:set(self.stages[storage.stage])
end

function questInteract(entityId)
  if self.onInteract then
    return self.onInteract(entityId)
  end
end

function update(dt)
  self.state:update(dt)

  if storage.complete then
    quest.setCanTurnIn(true)
  end
end

function craftMedical()
  quest.setProgress(nil)
  quest.setCompassDirection(nil)

  while storage.stage == 1 do
    quest.setObjectiveList({{self.descriptions.craftMedical, false}})
    if player.hasItem(self.medicalItem) then
      storage.stage = 2
    end
    coroutine.yield()
  end

  quest.setObjectiveList({})

  self.state:set(self.stages[storage.stage])
end

function collectIngredient1()
  quest.setCompassDirection(nil)

  while storage.stage == 2 do
    quest.setObjectiveList({{self.descriptions.collectIngredient1, false}})
    quest.setProgress(player.hasCountOfItem(self.ingredient1) / self.ingredient1Count)
    if player.hasItem({name = self.ingredient1, count = self.ingredient1Count}) then
      storage.stage = 3
    end
    coroutine.yield()
  end

  quest.setObjectiveList({})

  self.state:set(self.stages[storage.stage])
end

function collectIngredient2()
  quest.setProgress(nil)
  quest.setCompassDirection(nil)

  while storage.stage == 3 do
    quest.setObjectiveList({{self.descriptions.collectIngredient2, false}})
    quest.setProgress(player.hasCountOfItem(self.ingredient2) / self.ingredient2Count)
    if player.hasItem({name = self.ingredient2, count = self.ingredient2Count}) then
      storage.stage = 4
    elseif not player.hasItem({name = self.ingredient1, count = self.ingredient1Count}) then
      storage.stage = 2
    end
    coroutine.yield()
  end

  quest.setObjectiveList({})

  self.state:set(self.stages[storage.stage])
end

function craftMedicine()
  quest.setProgress(nil)
  quest.setCompassDirection(nil)

  while storage.stage == 4 do
    quest.setObjectiveList({{self.descriptions.craftMedicine, false}})

    if player.hasItem(self.medicineItem) then
      storage.stage = 5
    elseif not player.hasItem({name = self.ingredient2, count = self.ingredient2Count}) then
      storage.stage = 3
    end
    coroutine.yield()
  end

  quest.setObjectiveList({})

  self.state:set(self.stages[storage.stage])
end

function returnTutorial(dt)
  quest.setCompassDirection(nil)
    quest.setParameter("tutorial", {type = "entity", uniqueId = self.tutorialUid})
    quest.setIndicators({"tutorial"})
    quest.setObjectiveList({{self.descriptions.returnTutorial, false}})

    local trackTutorial = util.uniqueEntityTracker(self.tutorialUid, self.compassUpdate)
    while true do
      if not storage.complete then
        local tutorialResult = trackTutorial()
        questutil.pointCompassAt(tutorialResult)
        if tutorialResult then
          storage.complete = true
        end
      else
        quest.setCanTurnIn(true)
        quest.setIndicators({})
      end
      coroutine.yield()
    end
    self.state:set(self.stages[storage.stage])
end

function questComplete()
  setPortraits()
  questutil.questCompleteActions()
end