require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"

function init()
    self.tabsList = "scrollAreaTabs.tabList"
    self.bookList = "scrollAreaBooks.bookList"
    self.collectionList = "scrollAreaCollection.collectionList"

    self.iconSize = config.getParameter("iconSize")

    self.currentCollectables = {}
    self.playerCollectables = {}

    self.currentTab = false

    self.currentPage = 0
    self.maxPages = 0

    sortCodices()
    selectMode()
end

function sortCodices()
  self.codices = { }

  local promise = world.sendEntityMessage(player.id(), "cfGetCodices")
  while not promise do end
  local result = promise:result()
  if not result then return end

  for _, category in pairs(config.getParameter("tabs.codex")) do
    self.codices[category.data] = { }
  end

  for _, codex in pairs(result) do
    local species = root.assetJson(codex).species
    species = self.codices[species] ~= nil and species or "other"
    table.insert(self.codices[species], codex)
  end
end

function populateTabsList()
    widget.clearListItems(self.tabsList)
    local tabs = self.mode and config.getParameter("tabs.codex") or config.getParameter("tabs.collections")

    table.sort(tabs, function(a, b)
      return (a.weight or 0) < (b.weight or 0)
    end)

    for _, tab in pairs(tabs) do
      local item = widget.addListItem(self.tabsList)

      widget.setImage(string.format("%s.%s.icon", self.tabsList, item), util.absolutePath("/interface/scripted/collections/icons/", tab.icon))
      widget.setData(string.format("%s.%s", self.tabsList, item), { tab.name, tab.data })
    end
end

function populateBookList()
    widget.clearListItems(self.bookList)
    self.categoryName = widget.getData(string.format("%s.%s", self.tabsList, widget.getListSelected(self.tabsList)))[1]
    self.categorySpecies = widget.getData(string.format("%s.%s", self.tabsList, widget.getListSelected(self.tabsList)))[2]

    if self.categoryName and self.categorySpecies then
        local promise = world.sendEntityMessage(player.id(), "cfGetCodices")
        while not promise do end
        local result = promise:result()
        if not result then return end

        widget.setText("categoryLabel", "Choose " .. self.categoryName .. " Codex")

        for _, codex in pairs(self.codices[self.categorySpecies]) do
          local data = root.assetJson(codex)
          local dir = string.sub(codex, 1, string.len(codex) - string.len(data.id) - 6)
          local item = widget.addListItem(self.bookList)

          widget.setImage(string.format("%s.%s.icon", self.bookList, item), util.absolutePath(dir, data.icon))
          widget.setText(string.format("%s.%s.name", self.bookList, item), data.title)
          widget.setData(string.format("%s.%s", self.bookList, item), { data.longContentPages or data.contentPages, data.title, codex })
        end
    end
end

function populateCollectionList()
  widget.clearListItems(self.collectionList)
  local selectedData = widget.getData(string.format("%s.%s", self.tabsList, widget.getListSelected(self.tabsList)))

  if selectedData then
    local collection = root.collection(selectedData[2])
    widget.setText("collectionLabel", selectedData[1]);
    widget.setVisible("emptyLabel", false)

    self.currentCollectables = {}

    self.playerCollectables = {}
    for _,collectable in pairs(player.collectables(selectedData[2])) do
      self.playerCollectables[collectable] = true
    end

    local collectables = root.collectables(selectedData[2])
    table.sort(collectables, function(a, b) return a.order < b.order end)
    for _,collectable in pairs(collectables) do
      local item = widget.addListItem(self.collectionList)

      if collectable.icon ~= "" then
        local imageSize = rect.size(root.nonEmptyRegion(collectable.icon))
        local scaleDown = math.max(math.ceil(imageSize[1] / self.iconSize[1]), math.ceil(imageSize[2] / self.iconSize[2]))

        if not self.playerCollectables[collectable.name] then
          collectable.icon = string.format("%s?multiply=000000", collectable.icon)
        end
        widget.setImage(string.format("%s.%s.icon", self.collectionList, item), collectable.icon)
        widget.setImageScale(string.format("%s.%s.icon", self.collectionList, item), 1 / scaleDown)
      end
      widget.setText(string.format("%s.%s.index", self.collectionList, item), collectable.order)

      self.currentCollectables[string.format("%s.%s", self.collectionList, item)] = collectable;
    end
  else
    widget.setVisible("emptyLabel", true)
    widget.setText("collectionLabel", "Collection")
  end
end

function selectMode()
  -- 'true' = codex
  self.mode = widget.getSelectedData("lexiconModes") == "codex"

  self.currentContents = false

  widget.setVisible("scrollBGcodex", self.mode)
  widget.setVisible("scrollAreaBooks", self.mode)
  widget.setVisible("scrollAreaText", self.mode)
  widget.setVisible("categoryLabel", self.mode)
  widget.setVisible("titleLabel", self.mode)
  widget.setVisible("pageNum", self.mode)
  widget.setVisible("pageLabel", self.mode)
  widget.setVisible("prevButton", false)
  widget.setVisible("prevButtonDisabled", self.mode)
  widget.setVisible("nextButton", false)
  widget.setVisible("nextButtonDisabled", self.mode)

  widget.clearListItems(self.bookList)
  widget.setText("categoryLabel", "Category")
  widget.setText("pageNum", "0 of 0")
  widget.setText("titleLabel", "")
  widget.setText("scrollAreaText.pageText", "")

  widget.setVisible("scrollBGcollections", not self.mode)
  widget.setVisible("scrollAreaCollection", not self.mode)
  widget.setVisible("collectionLabel", not self.mode)

  widget.clearListItems(self.collectionList)
  widget.setText("collectionLabel", "Collection")

  populateTabsList()
end

function selectCategory()
  local selectedItem = widget.getListSelected(self.tabsList)
  if not selectedItem then return end

  self.currentTab = string.format("%s.%s", self.tabsList, selectedItem)

  if self.mode then
    populateBookList()
  else
    populateCollectionList()
  end
end

function selectCodex()
    if widget.getListSelected(self.bookList) then
        self.currentContents = widget.getData(string.format("%s.%s", self.bookList, widget.getListSelected(self.bookList)))[1]
        self.currentTitle = widget.getData(string.format("%s.%s", self.bookList, widget.getListSelected(self.bookList)))[2]

        if not self.currentContents then return end

        self.currentPage = 1
        self.maxPages = #self.currentContents

        widget.setText("scrollAreaText.pageText", self.currentContents[self.currentPage])
        widget.setText("pageNum", self.currentPage .. " of " .. self.maxPages)
        widget.setText("titleLabel", self.currentTitle)

        widget.setVisible("prevButton", false)
        widget.setVisible("prevButtonDisabled", true)
        widget.setVisible("nextButton", self.currentPage ~= self.maxPages)
        widget.setVisible("nextButtonDisabled", self.currentPage == self.maxPages)
    end
end

function prevPage()
    if self.currentContents then
        self.currentPage = util.clamp(self.currentPage - 1, 1, self.maxPages)

        widget.setText("scrollAreaText.pageText", self.currentContents[self.currentPage])
        widget.setText("pageNum", self.currentPage .. " of " .. self.maxPages)

        widget.setVisible("prevButton", self.currentPage ~= 1)
        widget.setVisible("prevButtonDisabled", self.currentPage == 1)
        widget.setVisible("nextButton", self.currentPage ~= self.maxPages)
        widget.setVisible("nextButtonDisabled", self.currentPage == self.maxPages)
    end
end

function nextPage()
    if self.currentContents then
        self.currentPage = util.clamp(self.currentPage + 1, 1, self.maxPages)

        widget.setText("scrollAreaText.pageText", self.currentContents[self.currentPage])
        widget.setText("pageNum", self.currentPage .. " of " .. self.maxPages)

        widget.setVisible("prevButton", self.currentPage ~= 1)
        widget.setVisible("prevButtonDisabled", self.currentPage == 1)
        widget.setVisible("nextButton", self.currentPage ~= self.maxPages)
        widget.setVisible("nextButtonDisabled", self.currentPage == self.maxPages)
    end
end

function createTooltip(screenPosition)
  if self.mode then return end

  for widgetName, collectable in pairs(self.currentCollectables) do
    if widget.inMember(widgetName, screenPosition) and self.playerCollectables[collectable.name] then
      local tooltip = config.getParameter("tooltipLayout")
      tooltip.title.value = collectable.title
      tooltip.description.value = collectable.description
      return tooltip
    end
  end
end