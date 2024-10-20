require "/interface/scripted/ceunipad/actions.lua"
require "/interface/scripted/ceunipad/conditions.lua"

local colorSub = {
  [ "^essential;" ] = "^#ffb133;",
  [ "^admin;" ] = "^#bf7fff;",
}

function init()
  self.list = "scrollArea.list"
  self.text = "textScrollArea.text"

  widget.setText(self.text, "Select any item on the left to continue...")

  loadIcons()
  populateList()
end

function loadIcons()
  self.icons = { }
  self.json = root.assetJson("/quickbar/icons.json")

  for _, item in pairs(self.json.items) do
    item.sort = string.lower(string.gsub(item.label, "(%b^;)", ""))
    item.label = string.gsub(item.label, "(%b^;)", colorSub)
    item.weight = item.weight or 0
    table.insert(self.icons, item)
  end

  -- Legacy icons
  for _, item in pairs(self.json.priority) do
    table.insert(self.icons, {
      sort = string.lower(string.gsub(item.label, "(%b^;)", "")),
      label = string.gsub("^essential;" .. item.label, "(%b^;)", colorSub),
      icon = item.icon,
      weight = -1100,
      action = item.pane and { "pane", item.pane } or item.scriptAction and { "_legacy", item.scriptAction } or { },
    })
  end
  if player.isAdmin() then
    for _, item in pairs(self.json.admin) do
      table.insert(self.icons, {
        sort = string.lower(string.gsub(item.label, "(%b^;)", "")),
        label = string.gsub("^admin;" .. item.label, "(%b^;)", colorSub),
        icon = item.icon,
        weight = -1000,
        action = item.pane and { "pane", item.pane } or item.scriptAction and { "_legacy", item.scriptAction } or { },
        condition = { "admin" }
      })
    end
  end
  for _, item in pairs(self.json.normal) do
    table.insert(self.icons, {
      sort = string.lower(string.gsub(item.label, "(%b^;)", "")),
      label = string.gsub(item.label, "(%b^;)", colorSub),
      icon = item.icon,
      weight = 0,
      action = item.pane and { "pane", item.pane } or item.scriptAction and { "_legacy", item.scriptAction } or { }
    })
  end

  table.sort(self.icons, function(a, b)
    return a.weight < b.weight or (a.weight == b.weight and a.sort < b.sort)
  end)
end

function populateList()
  widget.clearListItems(self.list)

  for _, icon in pairs(self.icons) do
    if not icon.condition or condition(table.unpack(icon.condition)) then
      local item = string.format("%s.%s", self.list, widget.addListItem(self.list))

      widget.setImage(string.format("%s.icon", item), icon.icon or "/assetmissing.png")
      widget.setText(string.format("%s.name", item), icon.label or "")
      widget.setData(item, { condition = icon.condition, action = icon.action, dismiss = icon.dismissQuickbar })
    end
  end
end

function selectItem()
  if not widget.getListSelected(self.list) then return end
  local selected = widget.getData(string.format("%s.%s", self.list, widget.getListSelected(self.list)))

  if not selected.condition or condition(table.unpack(selected.condition)) then
    string = action(table.unpack(selected.action))

    if string then widget.setText(self.text, string)
    elseif selected.dismiss == nil or selected.dismiss then pane.dismiss() end
  end
end