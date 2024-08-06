require "/scripts/util.lua"
require "/quests/scripts/questutil.lua"
require "/scripts/vec2.lua"
require "/quests/scripts/portraits.lua"

function init()
    storage.complete = storage.complete or false
    self.compassUpdate = config.getParameter("compassUpdate", 0.5)
    self.descriptions = config.getParameter("descriptions")
  
    self.gateRepairItem = config.getParameter("gateRepairItem")
    self.gateRepairCount = config.getParameter("gateRepairCount")
  
    self.gateUid = config.getParameter("gateUid")
    self.estherUid = config.getParameter("estherUid")
  
    self.findRange = config.getParameter("findRange")
    storage.bookmarked = storage.bookmarked or false
  
    setPortraits()
  
    storage.stage = storage.stage or 1
    self.stages = {
      findGate,
      collectRepairItem,
      repairGate,
      gateRepaired,
      findEsther
    }
  
    self.state = FSM:new()
    self.state:set(self.stages[storage.stage])
  
    storage.gateActive = storage.gateActive or false
  end

  function questInteract(entityId)
    if self.onInteract then
      return self.onInteract(entityId)
    end
  end
  
  function questStart()
    player.upgradeShip(config.getParameter("shipUpgrade"))
  end

  function update(dt)
    self.state:update(dt)
  
    -- Skip ahead if the gate is already active
    if storage.stage < 4 and gateActive() then
      storage.stage = 4
      self.state:set(gateRepaired)
    end
  
    if storage.complete then
      quest.setCanTurnIn(true)
    end
  end

  function gateActive()
    if storage.gateActive then return true end
  
    if not self.gatePromise then
      self.gatePromise = world.sendEntityMessage(self.gateUid, "isActive")
    else
      if self.gatePromise:finished() then
        if self.gatePromise:succeeded() then
          storage.gateActive = self.gatePromise:result() == true
        end
        self.gatePromise = nil
      end
    end
  
    return storage.gateActive
  end

  function findGate()
    quest.setProgress(nil)
    quest.setObjectiveList({{self.descriptions.findGate, false}})
  
    -- Wait until the player is no longer on the ship
    local findGate = util.uniqueEntityTracker(self.gateUid, self.compassUpdate)
    while true do
      local result = findGate()
      questutil.pointCompassAt(result)
      if result and world.magnitude(mcontroller.position(), result) < self.findRange then
        self.state:set(gateFound)
      end
      coroutine.yield()
    end
  
    self.state:set(self.stages[storage.stage])
  end
  
  function gateFound()
    quest.setProgress(nil)
    quest.setCompassDirection(nil)
    player.radioMessage("gaterepair-gateFound1")
    player.radioMessage("gaterepair-gateFound1b")
    player.radioMessage("gaterepair-gateFound2")
    storage.stage = 2
  
    util.wait(14)
  
    self.state:set(self.stages[storage.stage])
  end
  
  function collectRepairItem()
    quest.setCompassDirection(nil)
  
    while storage.stage == 2 do
      quest.setObjectiveList({{self.descriptions.collectRepairItem, false}})
      quest.setProgress(player.hasCountOfItem(self.gateRepairItem) / self.gateRepairCount)
      if player.hasItem({name = self.gateRepairItem, count = self.gateRepairCount}) then
        storage.stage = 3
      end
      coroutine.yield()
    end
  
    quest.setObjectiveList({})
  
    self.state:set(self.stages[storage.stage])
  end
  
  function repairGate()
    quest.setCompassDirection(nil)
    quest.setProgress(nil)
  
    quest.setParameter("ancientgate", {type = "entity", uniqueId = self.gateUid})
    quest.setIndicators({"ancientgate"})
  
    quest.setObjectiveList({
      {self.descriptions.repairGate, false}
    })
  
    local findGate = util.uniqueEntityTracker(self.gateUid, self.compassUpdate)
    while storage.stage == 3 do
      questutil.pointCompassAt(findGate())
  
      -- Go back to last stage if player loses core fragments
      if not player.hasItem({name = self.gateRepairItem, count = self.gateRepairCount}) then
        storage.stage = 2
        self.state:set(self.stages[storage.stage])
      end
  
      coroutine.yield()
    end
  
    self.onInteract = nil
    self.state:set(self.stages[storage.stage])
  end
  
  function gateRepaired()
    self.onInteract = nil
    quest.setCompassDirection(nil)
    quest.setProgress(nil)
    quest.setIndicators({})
  
    storage.stage = 5
  
    player.radioMessage("gaterepair-gateOpened1")
    player.radioMessage("gaterepair-gateOpened2")
  
    self.state:set(self.stages[storage.stage])
  end
  
  function findEsther(dt)
    quest.setCompassDirection(nil)
    quest.setParameter("esther", {type = "entity", uniqueId = self.estherUid})
    quest.setIndicators({"esther"})
    quest.setObjectiveList({{self.descriptions.findEsther, false}})
  
    local trackEsther = util.uniqueEntityTracker(self.estherUid, self.compassUpdate)
    local trackGate = util.uniqueEntityTracker(self.gateUid, self.compassUpdate)
    while true do
      if not storage.complete then
        local estherResult = trackEsther()
        questutil.pointCompassAt(estherResult)
        if estherResult then
          if not storage.bookmarked then
            player.addTeleportBookmark(config.getParameter("outpostBookmark"))
            storage.bookmarked = true
          end
          if world.magnitude(estherResult, mcontroller.position()) < self.findRange then
            player.playCinematic(config.getParameter("findEstherCinema"))
            storage.complete = true
          end
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