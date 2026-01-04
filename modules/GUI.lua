--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>PLAYER</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>PLAYER_init</name>
--##				<packageName></packageName>
--##				<script>PLAYER = PLAYER or MundronClassMethods:new{
PLAYER = PLAYER or MundronClassMethods:new{
  _name = "PLAYER",
  _module = "GUI",
  _version = "1.0.0",
  config = {
    attributes={con=-99, str=-99, dex=-99, int=-99}
  },
  files ={profile={["COMPACT"]={world=0}}}
}

function PLAYER:post_load_data()
  if PLAYER.con() == 99 then
    tempTimer(10, [[iprint("Setze die Attribute mit #attr &lt;Ausdauer&gt; &lt;Intelligenz&gt; &lt;Staerke&gt; &lt;Geschick&gt; fuer die Anzeige", "GUI")]])
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>PLAYER_core</name>
--##				<packageName></packageName>
--##				<script>function PLAYER.playername()
function PLAYER.playername()
  return table.get(gmcp or {}, "MG.char.base.name", getProfileName())
end

function PLAYER.nameplate()
  local info = table.get(gmcp or {}, "MG.char.info", {level=0, guild_level=0})
  local result = f"{PLAYER.playername()} [{info.level}&amp;nbsp;-&amp;nbsp;{info.guild_level}]"
  return result
end

function PLAYER.guild()
  return table.get(gmcp or {}, "MG.char.base.guild")
end

function PLAYER.wimpy()
  return table.get(gmcp or {}, "MG.char.wimpy.wimpy", 0)
end

function PLAYER.wimpy_text()
  local wimpy = PLAYER.wimpy()
  local result
  if wimpy &gt; 0 then
    result = f"Vorsicht: {wimpy}"
  else 
    result = "Vorsicht: Prinz Eisenherz"
  end
  return result
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>PLAYER_vitals</name>
--##				<packageName></packageName>
--##				<script>function PLAYER.vitals(field)
function PLAYER.vitals(field)
  local value = 999
  local prefix = ""
  if field == "poison" then
    value = 0
  end
  if string.startswith(field, "max") then
    prefix = "max"
  end
  return table.get(gmcp or {}, f"MG.char.{prefix}vitals.{field}", value)
end

for _, field in pairs({"hp", "sp", "poison"}) do
  PLAYER[field] = function() return PLAYER.vitals(field) end
  local max_field = f"max_{field}"
  PLAYER[max_field] = function() return PLAYER.vitals(max_field) end
end

function PLAYER.poison_text()
  local poison = PLAYER.poison()
  if poison == 0 then
    return "Gesund"
  elseif poison &lt; 2 then
    return "Gift"
  elseif poison &lt; 4 then
    return "GIFT"
  end
  return "!! G I F T !!"
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>PLAYER_kills</name>
--##				<packageName></packageName>
--##				<script>function PLAYER.kills_text()
function PLAYER.kills_text()
  if not EK or not EK.config.tracking then
    return "~ Kein EK-Tracking ~"
  end
  local kill_count = EK:kill_count()
  local result = f"EK-Anzahl: {kill_count} [{EK.data.unknown_kills}]"
  local delta = table.get(EK, "data.plate_number", kill_count) - kill_count
  if delta &gt; 0 then
    result = f"{result} (+{delta})"
  elseif delta &lt; 0 then
    result = f"{result} ({delta})"
  end
  return result
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>PLAYER_attributes</name>
--##				<packageName></packageName>
--##				<script>function PLAYER.generic_attribute_text(name)
function PLAYER.generic_attribute_text(name)
  local map = {con="A", str="K", int="I", dex="G"}
  local real_attr, diff = PLAYER.generic_attribute_values(name)
  local result = f"&amp;nbsp;{map[name]}: {real_attr}"
  if diff &gt; 0 then
    result = f"{result}+{diff}"
  elseif diff &lt; 0 then
    result = f"{result}{diff}"
  end
  return result
end

function PLAYER.generic_attribute_values(name)
  local real_attr = table.get(
    gmcp or {}, 
    f"MG.char.attributes.{name}", 
    PLAYER.config.attributes[name]
  )
  local diff = real_attr - PLAYER.config.attributes[name]
  return real_attr-diff, diff
end

for _, attr in pairs({"con", "str", "int", "dex"}) do
  PLAYER[f"{attr}_text"] = function() return PLAYER.generic_attribute_text(attr) end
  PLAYER[attr] = function() return PLAYER.generic_attribute_values(attr) end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>PLAYER_position</name>
--##				<packageName></packageName>
--##				<script>function PLAYER.world()
function PLAYER.world()
  return table.get(PLAYER, "data.world", 0)
end

function PLAYER.change_world(new_world)
  table.set(PLAYER, "data.world", new_world)
end

function PLAYER.room_id()
  return table.get(gmcp, "MG.room.info.id")
end

function PLAYER.room_id_text()
  local _id = PLAYER.room_id() or "~"
  local result = f"[{_id:sub(1, 5)}]"
  return result
end

function PLAYER.region()
  local world = PLAYER.world()
  local result = table.get(gmcp, "MG.room.info.domain") or "~"
  if world &gt; 0 then
    result = f"Para-{world}-{result}"
  end
  return result
end

function PLAYER.node()
  return table.get(PathData or {}, {"node_by_id", PLAYER.room_id() or "~"})
end

function PLAYER.node_factor()
  if type(PLAYER.node()) == "string" then
    return 0.5
  end
  return 0
end

function PLAYER.node_text()
  local node = PLAYER.node() or "~"
  local result = f"&amp;nbsp;WS: {node}"
  return result
end

function PLAYER.room_info()
  return table.get(gmcp, "MG.room.info.short", "~")
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>PLAYER_migration</name>
--##				<packageName></packageName>
--##				<script>function PLAYER:migrate_profile(old_version)
function PLAYER:migrate_profile(old_version)
  if old_version &lt; "1.0.0" then
    -- nothing to do, not relevant
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>HYDRA</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>HYDRA_init</name>
--##				<packageName></packageName>
--##				<script>HYDRA = HYDRA or MundronClassMethods:new{
HYDRA = HYDRA or MundronClassMethods:new{
  _name="HYDRA",
  _module="GUI",
  _version="1.0.0",
  config = {MAX_TIME=2040, NEST_TIME=90},
  data = {
    time = 0,
  }
}
--##}</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>HYDRA_functions</name>
--##				<packageName></packageName>
--##				<script>function HYDRA:init()
function HYDRA:init()
  HYDRA.data.time = HYDRA.config.MAX_TIME + 1
  enableTimer("timer_for_hydra")
  self:decrease_time()
end

function HYDRA:close()
  disableTimer("timer_for_hydra")
  MainGUI:update_label("hydra", false)
end

local function timeformat(seconds)
  local _, mm, ss = shms(seconds)
  return f"{mm}:{ss}"
end

function HYDRA:is_in_nest()
  return self.data.time + self.config.NEST_TIME &gt; self.config.MAX_TIME
end

function HYDRA:decrease_time()
  if self.data.time == 0 then
    MainGUI:update_label("hydra", false)
    return
  end
  
  self.data.time = math.max(self.data.time - 1, 0)
  if self:is_in_nest() then
    MainGUI:update_label("hydra", "nest")
  else
    MainGUI:update_label("hydra", "tal")
  end
end

-- function for MainGUI
function HYDRA.status()
  if HYDRA.data.time == 0 then
    return ""
  end
  local result = "Hydra (Tal): "
  if HYDRA:is_in_nest() then
    result = "Hydra (Nest): "
  end
  local _, mm, ss = shms(HYDRA.data.time)
  result = f"{result}{mm}:{ss}"
  return result
end

--##</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>GUITemplate</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>GUITemplate_init</name>
--##				<packageName></packageName>
--##				<script>GUITemplate = GUITemplate or MundronClassMethods:extend({_name="GUITemplate"})
GUITemplate = GUITemplate or MundronClassMethods:extend({_name="GUITemplate"})

function GUITemplate:new(init)
  local obj = MundronClassMethods.new(self, init)

  for _, field in pairs({"labels", "containers", "gauges", "state"}) do
    obj[field] = obj[field] or {}
  end
  
  return obj
end

function GUITemplate:build_base()
  self:create_container("_BASE", self.config)

  local border_label = self:create_label("_BORDER_LABEL", {0, 0, "100%", "100%"})
  border_label:setStyleSheet(
    "border-width: 5px;border-style: solid;border-color: rgb(100,50,0);border-radius: 5px;background-color: transparent"
  )

  local image_label = self:create_label("_IMAGE_LABEL", {5,5,-5, -5})
  image_label:setTiledBackgroundImage(getRepoPicturePath("bg.gif"))
end

--##</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>GUITemplate_container</name>
--##				<packageName></packageName>
--##				<script>function GUITemplate:create_container(name, size, parent_name)
function GUITemplate:create_container(name, size, parent_name)
  local containers = table.get(self, "containers", {})
  if containers[name] then
    local msg = f"Container with name {name} already exists for {self.name}/{self._name}" 
    printError(msg, true, true)
  end
  local parent = self.containers[parent_name or "_BASE"]
  local x, y, width, height = unpack(size)
  local new_container = Geyser.Container:new(
    {
      name = self:guid(name), x = x, y = y, width = width, height = height,
    },
    parent
  )
  self:log(f"Create container {name} added to container {(parent or {}).name}")
  containers[name] = new_container
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>GUITemplate_label</name>
--##				<packageName></packageName>
--##				<script>function GUITemplate:create_label(name, size, text, container_name)
function GUITemplate:create_label(name, size, text, container_name)
  if self.labels[name] then
    printError(f"Label with name {name} already exists", true, true)
  end
  local x, y, width, height = unpack(size)
  local props =  {name = self:guid(name), x = x, y = y, width = width, height = height}
  local container = self.containers[container_name or "_BASE"]
  local new_label = Geyser.Label:new(props, container)
  self:log(f"Create label {name} added to container {container.name}")
  new_label:setFontSize(9)
  new_label:setColor("transparent")
  if not text then
    text = function(context) return context end
  end
  self.labels[name] = {object=new_label, text=text, states={}}
  self:update_label(name)
  return new_label
end

function GUITemplate:add_label_states(name, states, default)
  table.update(self.labels[name].states, states)
  if default then
    self:update_label_state(name, default)
  end
end

function GUITemplate:update_label_state(name, new_state_id)
  if new_state_id == self.labels[name].current then
    return "black"
  end
  local label_ref = self.labels[name]
  if not label_ref then
    self:error(f"{self._name} has no label state named {name}")
  end
  label_ref.current = new_state_id
  local label = label_ref.object
  local state=label_ref.states[label_ref.current] or {}
  if type(state.bg) == "table" then
    label:setColor(unpack(state.bg))
  elseif type(state.bg) == "string" then
    label:setColor(state.bg)
  end
  return state.fg or "black"
end

function GUITemplate:update_label(name, state_id, ...)
  local label_ref = self.labels[name]
  if state_id == nil then
    state_id = label_ref.current
  end
  local fg = self:update_label_state(name, state_id)
  local label, text = label_ref.object, label_ref.text
  if type(text) == "string" then
    label:echo(f(text), fg)
  elseif type(text) == "function" then
    label:echo(text(...), fg)
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>GUITemplate_gauge</name>
--##				<packageName></packageName>
--##				<script>local function relative_value(current, max)
local function relative_value(current, max)
  local result = f"{current}/{max} ({math.floor(100*current/max)}%)"
  return result
end

function GUITemplate:create_gauge(name, size, color, container_name)
  if self.gauges[name] then
    printError(f"Gauge with name {name} already exists", true, true)
  end
  local x, y, width, height = unpack(size)
  local container = self.containers[container_name or "_BASE"]
  self:log(f"Create gauge {name} in the container {container.name}")
  
  -- border and background
  local border = Geyser.Gauge:new(
    {name = self:guid(f"{name}_anzeige_border"), x = x, y = y, width = width, height = 8}, 
    container
  )
  border:setColor(0, 0, 0)
  
  -- Main bar
  local bar = Geyser.Gauge:new(
    {name = self:guid(f"{name}_anzeige"), x = x+1, y = y+1, width = width-1, height = 6}, 
    container
  )
  bar:setColor(unpack(color))
  
  -- label to display status
  local title = Geyser.Label:new(
    {name = self:guid(f"{name}_titel"), x = x, y = y+8, width = width, height = 15}, 
    container
  )
  title:echo(relative_value(999, 999), "black")
  title:setAlignment("c")
  title:setBold(true)
  title:setColor("transparent")
  self.gauges[name] = {title=title, border=border, bar=bar}
  return self.gauges[name]
end

function GUITemplate:update_gauge(name, current_value, last_value, max_value)
  local gauge_ref = self.gauges[name]
  gauge_ref.bar:setValue(current_value, max_value)
  gauge_ref.title:echo(relative_value(current_value, max_value), "black")
end

--##</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>GUITemplate_misc</name>
--##				<packageName></packageName>
--##				<script>function GUITemplate:guid(name)
function GUITemplate:guid(name)
  local result = f"{self._name}_{self._module}_{name}"
  return result
end

local function profile(object)
  local result = f"position=({object.x}/{object.y}) size=({object.width}/{object.height})"
  return result
end

function GUITemplate:list()
  self:info(f"List of all containers:")
  for name, container in pairs(self.containers) do
    local data = profile(container)
    local text = f"{name}: {data}"
    print(text)
  end
  
  self:info(f"List of all labels:")
  for name, label in pairs(self.labels) do
    local data = profile(label.object)
    local text = f"{name}: {data}"
    print(text)
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>MainGUI</name>
--##			<packageName></packageName>
--##			<script>-------------------------------------------------
-------------------------------------------------
--         Put your Lua functions here.        --
--                                             --
-- Note that you can also use external Scripts --
-------------------------------------------------

--##</script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>MainGUI_init</name>
--##				<packageName></packageName>
--##				<script>MainGUI = MainGUI or GUITemplate:new{
MainGUI = MainGUI or GUITemplate:new{
  _name = "MainGUI",
  _module = "GUI",
  _version = "1.0.0",
  config = {0, -150, 510, 150},
  state = {build=false}
}

function MainGUI:init()
  if self.state.build then
    self:info("MainGUI bereits erstellt")
    return
  end
  self:build_base()
  setBorderBottom(self.config[4])
  local margin = 15
  self:create_container("row1", {margin, 10, -1*margin, 17})
  self:create_container("row2", {margin, 30, -1*margin, 17})
  self:create_container("row3", {margin, 50, -1*margin, 25})
  self:create_container("row4", {margin, 75, -1*margin, 25})
  self:create_container("row5", {margin, 100, -1*margin, 17})
  self:create_container("row6", {margin, 120, -1*margin, 17})
  
  --------------------------------------------
  -- row 1
  --------------------------------------------
  self:create_label("nameplate", {0,0, 150, 15}, PLAYER.nameplate, "row1")
  self:add_label_states(
    "nameplate", 
    {normal={bg="transparent"}, highlight={bg={0,200,0,150}}},
    "normal"
  )
  local poison_label = self:create_label("poison", {150, 0, 50, 17}, PLAYER.poison_text, "row1")
  poison_label:setAlignment("c")
  for i=1,10,1 do
    self:add_label_states("poison", {[i]={bg={255,25*i,0,155+10*i}}})
  end
  self:add_label_states("poison", {[0]={bg="transparent"}}, 0)
  local wimpy_label = self:create_label("wimpy", {210, 0, -5, 17}, PLAYER.wimpy_text, "row1")
  
  --------------------------------------------
  -- row 2
  --------------------------------------------
  local kill_label = self:create_label("kills", {0, 0, 150, 17}, PLAYER.kills_text, "row2")
  
  local delta = 60
  for i,field in ipairs({"con", "int", "str", "dex"}) do
    local text_field = f"{field}_text"
    self:create_label(field, {210+(i-1)*delta, 0, delta, 17}, PLAYER[text_field], "row2")
    self:add_label_states(
      field,{
        [-5]={bg="black", fg="white"},
        [-4]={bg={250,50,0,200}},
        [-3]={bg={250,150,0,170}},
        [-2]={bg={250,200,0,150}},
        [-1]={bg={250,250,0,100}},
        [0]={bg="transparent"},
        [1]={bg={0,200,50,100}},
        [2]={bg={0,210,40,150}},
        [3]={bg={0,220,40,250}},
        [4]={bg={0,200,200,150}},
        [5]={bg={0,190,230,250}},
      }, 
      0)
  end
  
  --------------------------------------------
  -- row 3
  --------------------------------------------
  self:create_gauge("hp", {10, 2, -10, 20}, {0, 180, 50}, "row3")
  
  --------------------------------------------
  -- row 4
  --------------------------------------------
  self:create_gauge("sp", {10, 2, -10, 20}, {0, 50, 250}, "row4")
  
  --------------------------------------------
  -- row 5
  --------------------------------------------
  self:create_label("position_background", {0, 0, "100%", "100%"}, nil, "row5")
  self:add_label_states("position_background", {[true] = {bg = "transparent"}, [false]={bg="red"}}, PLAYER.world() == 0)
  self:create_label("room_id", {0, 0, 50, 17}, PLAYER.room_id_text, "row5")
  local node_label = self:create_label("node", {50, 0, 80, 17}, PLAYER.node_text, "row5")
  node_label:setAlignment("c")
  self:add_label_states("node", { 
    [0]={bg="transparent", fg="black"},
    [0.5]={bg={0,220,100,200}, fg="black"},
    [1] = {bg="transparent", fg="white"},
    [1.5]={bg={0,220,100,200}, fg="white"}
  }, PLAYER.node_factor())
  self:create_label("room_info", {135, 0, 235, 17}, PLAYER.room_info, "row5")
  local region_label = self:create_label("region", {370, 0, 100, 17}, PLAYER.region, "row5")
  region_label:setAlignment("c")
  
  for _, field in pairs({"room_id", "room_info", "region"}) do
    self:add_label_states(field, {[0] = {fg = "black"}, [1]={fg="white"}}, math.min(PLAYER.world(), 1))
  end
  
  --------------------------------------------
  -- row 6
  --------------------------------------------
  self:create_label("hydra", {0, 0, 220, 17}, HYDRA.status, "row6")
  self:add_label_states("hydra", {
    [false]={bg="transparent"},
    nest={bg="blue", fg="white"},
    tal={bg="red", fg="white"}
  })
    
  --------------------------------------------
  -- Extra calls
  --------------------------------------------
  
  tempTrigger(
    "Du nimmst schon am Spiel teil!",
    function ()
      if EK.config.tracking then
        tempTimer(2, function() send("lies plakette") end)
      end
    end
  )
    
  self.state.build = true
end

if not MainGUI.state.build then
  MainGUI:init()
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>MainGUI_misc</name>
--##				<packageName></packageName>
--##				<script>function MainGUI:update_world(new_world)
function MainGUI:update_world(new_world)
  PLAYER.change_world(new_world)
  local max_world = math.min(new_world, 1)
  for _, field in pairs({"position_background", "room_id", "room_info", "region"}) do
    self:update_label(field, max_world)
  end
  self:update_label("node", max_world + PLAYER.node_factor())
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>main_gui_update_base</name>
--##				<packageName></packageName>
--##				<script>

--- Basisdaten erzeugen. Sowohl Name/Level von der MainGUI als auch Wege

function main_gui_update_base()
  MainGUI:update_label("nameplate")
  if PathData then
    PathData.catch_path_end_action = f("{PLAYER.playername()} {PathData.path_end_action}") 
  end
end
--##end</script>
--##				<eventHandlerList>
--##					<string>gmcp.MG.char.base</string>
--##					<string>gmcp.MG.char.info</string>
--##				</eventHandlerList>
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>main_gui_update_vitals</name>
--##				<packageName></packageName>
--##				<script>local function ivalue(a, b, c, t)
local function ivalue(a, b, c, t)
  -- for t from 0 to 1/3 the value goes linearly from a to b
  -- and for t from 1/3 to 1 the value goes linearly from b to c
  local result
  if 3 * t &lt; 1 then
    result = a + 3 * (b - a) * t
  else
    result = b + (c - b) * (3 * t - 1) / 2
  end
  return result - (result % 1)
end

function main_gui_hp_anzeige_faerben()
  -- Je nach LP Verlust wird Farbe gruen/gelb/rot
  local lp_quote = PLAYER.hp() / PLAYER.max_hp()
  MainGUI.gauges.hp.bar:setColor(ivalue(255, 200, 0, lp_quote), ivalue(0, 200, 180, lp_quote), 50)
end

function main_gui_hp_anzeige_entblinken()
  table.set(MainGUI, "data.hp.flash", false)
  main_gui_hp_anzeige_faerben()
end

function main_gui_hp_anzeige_blinken(dauer)
  table.set(MainGUI, "data.hp.flash", true)
  MainGUI.gauges.hp.bar:setColor(255, 0, 50)
  -- rot
  tempTimer(dauer, [[ main_gui_hp_anzeige_entblinken() ]])
end

function main_gui_update_vitals()
  -- falls man stirbt, landet man in Normal:
  if PLAYER.world() &gt; 0 and PLAYER.hp() &lt; 0 then
    MainGUI:update_world(new_world)
  end
  
  -- Treffer? Dann LP Balken blinken lassen
  if PLAYER.hp() - table.get(PLAYER, "data.hp", PLAYER.hp()) &lt; 0 then
    main_gui_hp_anzeige_blinken(0.2)
  elseif not table.get(MainGUI, "data.hp.flash") then
    main_gui_hp_anzeige_faerben()
  end
  
  -- Werte der Balken aktualisieren
  for _, vital in pairs({"hp", "sp"}) do
    local old_value = table.get(PLAYER, {"data", vital}, PLAYER[f"max_{vital}"]())
    MainGUI:update_gauge(vital, PLAYER[vital](), old_value, PLAYER[f"max_{vital}"]())
    table.set(PLAYER, {"data", vital}, PLAYER[vital]())
  end
    
  
end

--##</script>
--##				<eventHandlerList>
--##					<string>gmcp.MG.char.vitals</string>
--##					<string>gmcp.MG.char.maxvitals</string>
--##				</eventHandlerList>
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>main_gui_update_poison</name>
--##				<packageName></packageName>
--##				<script>function main_gui_update_poison()
function main_gui_update_poison()
  MainGUI:update_label("poison", PLAYER.poison())
end
--##end</script>
--##				<eventHandlerList>
--##					<string>gmcp.MG.char.vitals</string>
--##				</eventHandlerList>
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>main_gui_update_wimpy</name>
--##				<packageName></packageName>
--##				<script>function main_gui_update_wimpy()
function main_gui_update_wimpy()
  MainGUI:update_label("wimpy")
end
--##end</script>
--##				<eventHandlerList>
--##					<string>gmcp.MG.char.wimpy</string>
--##				</eventHandlerList>
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>main_gui_update_room</name>
--##				<packageName></packageName>
--##				<script>function main_gui_update_room()
function main_gui_update_room()
  MainGUI:update_label("room_id")
  MainGUI:update_label("node", PLAYER.node_factor())
  MainGUI:update_label("room_info")
  MainGUI:update_label("region")
end
--##end</script>
--##				<eventHandlerList>
--##					<string>gmcp.MG.room</string>
--##				</eventHandlerList>
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>main_gui_update_attributes</name>
--##				<packageName></packageName>
--##				<script>function main_gui_update_attributes()
function main_gui_update_attributes()
  for _, field in pairs({"con", "int", "str", "dex"}) do
    local _, diff = PLAYER[field]()
    diff = math.min(math.max(diff, -5), 5)
    MainGUI:update_label(field, diff)
  end
end
--##end</script>
--##				<eventHandlerList>
--##					<string>gmcp.MG.char.attributes</string>
--##				</eventHandlerList>
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>ExitGUI</name>
--##			<packageName></packageName>
--##			<script>-------------------------------------------------
-------------------------------------------------
--         Put your Lua functions here.        --
--                                             --
-- Note that you can also use external Scripts --
-------------------------------------------------

--##</script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>ExitGUI</name>
--##				<packageName></packageName>
--##				<script>ExitGUI = ExitGUI or GUITemplate:new{
ExitGUI = ExitGUI or GUITemplate:new{
  _name = "ExitGUI",
  _module = "GUI",
  _version = "1.0.0",
  config = {-150, -150, 150, 150},
  data = {directions={}, current={}},
  state = {build=false}
}

function ExitGUI:init()
  if self.state.build then
    self:info("ExitGUI bereits erstellt")
    return
  end
  self:build_base()
  
  for _, post in pairs({"en", "oben", "unten"}) do
    for xd, main in ipairs({"west", "", "ost"}) do
      for yd, pre in ipairs({"nord", "", "sued"}) do
        local dir = f"{pre}{main}{post}"
        if dir == "en" then
          dir = "raus"
        end
        self.data.directions[dir] = true
        local label = self:create_label(dir, {-25+xd*40, -25+yd*40, 40, 40})
        label:setColor("transparent")
        label:setBackgroundImage(getRepoPicturePath(f"{dir}.png"))
        label:hide()
      end
    end
  end
    
  self.state.build = true
end

ExitGUI:init()
--##ExitGUI:init()</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>update_exits</name>
--##				<packageName></packageName>
--##				<script>-------------------------------------------------
-------------------------------------------------
--         Put your Lua functions here.        --
--                                             --
-- Note that you can also use external Scripts --
-------------------------------------------------

function update_exits()
  local newdir = {}
  local nextdir = {}
  -- Pruefe, welche Ausgaenge wegkommen und welche hinzukommen
  for _, dir in ipairs(gmcp.MG.room.info.exits) do
    -- in ExitGUI.data.current waren alle vorigen Ausgaenge.
    -- falls eines der vorigen Ausgaenge wieder ein Ausgang
    -- ist, dann brauchen wir nichts zu aendern. Deswegen
    -- werden diese aus der Liste geloescht, so dass am Ende
    -- ExitGUI.data.current nur die Ausgaenge enthaelt, die es jetzt
    -- nicht mehr gibt, also geloescht werden muessen.
    -- Andererseits haben wir einen neuen Ausgang, den wir
    -- hinzufuegen muessen, was in der zusaetzlichen Liste
    -- newdir gespeichert wird.
    if ExitGUI.data.directions[dir] then -- nur zulaessige Richtungen beachten
      if ExitGUI.data.current[dir] then
        ExitGUI.data.current[dir] = nil
      else
        newdir[dir] = true
      end
      nextdir[dir] = true
    end
  end
  -- Alle Ausgaenge vom Vorraum, die es hier nicht mehr gibt,
  -- muessen geloescht werden.
  for dir, _ in pairs(ExitGUI.data.current) do
    ExitGUI.labels[dir].object:hide()
  end
  -- Ausgaenge die neu hinzu kommen muessen angezeigt werden.
  for dir, _ in pairs(newdir) do
    ExitGUI.labels[dir].object:show()
  end
  -- schliesslich speichern wir nun in AK.directions alle Ausgaenge
  -- diesen Raumes um es bei Raumaenderung wieder nuetzen zu koennen.
  ExitGUI.data.current = nextdir
end
--##end</script>
--##				<eventHandlerList>
--##					<string>gmcp.MG.room.info</string>
--##				</eventHandlerList>
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>KlerusGUI</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>KlerusGUI_init</name>
--##				<packageName></packageName>
--##				<script>KlerusGUI = KlerusGUI or GUITemplate:new{
KlerusGUI = KlerusGUI or GUITemplate:new{
  _name = "KlerusGUI",
  _module = "GUI",
  _version = "1.0.0",
  config = {510, -150, 100, 150},
  state = {build=false},
  hidden = false
}

function KlerusGUI:init()
  if self.state.build then
    self:info("KlerusGUI bereits erstellt")
    return
  end
  self:build_base()
  
  local margin = 15
  self:create_container("row1", {margin, 10, -1*margin, 17})
  self:create_container("row2", {margin, 45, -1*margin, 17})
  self:create_container("row3", {margin, 75, -1*margin, 17})
  self:create_container("row4", {margin, 105, -1*margin, 17})

  --------------------------------------------
  -- row 1
  --------------------------------------------
  self:create_label("elementarsphaere", {0, 0, 30, 20}, "EW", "row1")
  self:add_label_states("elementarsphaere", {
    Kein={bg="transparent"},
    Feuer={bg={255,0,0}, fg="white"},
    Erde={bg={170,85,0}, fg="white"},
    Wasser={bg={0,0,255}, fg="white"},
    Kaelte={bg={0,255,255}},
    Luft={bg="white"}
  })
  self:create_label("heiligenschein", {40, 0, 30, 20}, "HS", "row1")
  self:add_label_states("heiligenschein", {
    [true]={bg="yellow"}, [false]={bg="transparent"}
  })
  
  --------------------------------------------
  -- row 2
  --------------------------------------------
  self:create_label("elementarschild", {0, 0, 30, 20}, "ES", "row2")
  self:add_label_states("elementarschild", {
    Kein={bg="transparent"},
    Feuer={bg={255,0,0}, fg="white"},
    Erde={bg={170,85,0}, fg="white"},
    Wasser={bg={0,0,255}, fg="white"},
    Kaelte={bg={0,255,255}},
    Luft={bg="white"},
    Saeure={bg="yellow"}
  })
  self:create_label("schutzhand", {40, 0, 30, 20}, "SH", "row2")
  self:add_label_states("schutzhand", {
    [true]={bg="white"}, [false]={bg="transparent"}
  })
  --------------------------------------------
  -- row 3
  --------------------------------------------
  self:create_label("weihe", {0, 0, 30, 20}, "WW", "row3")
  self:add_label_states("weihe", {
    [true]={bg="white"}, [false]={bg="transparent"}
  })
  self:create_label("messerkreis", {40, 0, 30, 20}, "MK", "row3")
  self:add_label_states("messerkreis", {
    [true]={bg="white"}, [false]={bg="transparent"}
  })
  --------------------------------------------
  -- row 4
  --------------------------------------------
  self:create_label("goettermacht", {0, 0, 30, 20}, "GM", "row4")
  self:add_label_states("goettermacht", {
    [true]={bg="white"}, [false]={bg="transparent"}
  })
  self:create_label("spaltung", {40, 0, 30, 20}, "SP", "row4")
  self:add_label_states("spaltung", {
    [true]={bg={255,170,125}}, [false]={bg="transparent"}
  })
  
  for _,label_ref in pairs(self.labels) do
    label_ref.object:setAlignment("c")
  end
    
  self.state.build = true
end

KlerusGUI:init()
--##KlerusGUI:init()</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>klerus_gui_update_base</name>
--##				<packageName></packageName>
--##				<script>function klerus_gui_update_base()
function klerus_gui_update_base()
  if KlerusGUI.hidden or not PLAYER.guild() or PLAYER.guild() == "klerus" then
    return
  end
  KlerusGUI:log(f"Hide because found guild is {PLAYER.guild()}")
  KlerusGUI.containers["_BASE"]:hide()
  KlerusGUI.hidden = true
end
--##end</script>
--##				<eventHandlerList>
--##					<string>gmcp.MG.char.base</string>
--##				</eventHandlerList>
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>update_klerus_spaltung</name>
--##				<packageName></packageName>
--##				<script>-------------------------------------------------
-------------------------------------------------
--         Put your Lua functions here.        --
--                                             --
-- Note that you can also use external Scripts --
-------------------------------------------------

function update_klerus_spaltung()
  KlerusGUI:update_label_state("spaltung", false)
end
--##end</script>
--##				<eventHandlerList>
--##					<string>gmcp.MG.room</string>
--##				</eventHandlerList>
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>WerwolfGUI</name>
--##			<packageName></packageName>
--##			<script>-------------------------------------------------
-------------------------------------------------
--         Put your Lua functions here.        --
--                                             --
-- Note that you can also use external scripts --
-------------------------------------------------

--##</script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>WerwolfGUI_init</name>
--##				<packageName></packageName>
--##				<script>WerwolfGUI = WerwolfGUI or GUITemplate:new{
WerwolfGUI = WerwolfGUI or GUITemplate:new{
  _name = "WerwolfGUI",
  _module = "GUI",
  _version = "1.0.0",
  config = {510, -150, 100, 150},
  state = {build=false},
  hidden = false
}

function WerwolfGUI:init()
  if self.state.build then
    self:info("WerwolfGUI bereits erstellt")
    return
  end
  self:build_base()
  
  self:create_label("form", {15, 15, 70, 20}, function(t) return t or "Mensch (M)" end)
  self:add_label_states("form", {
    Mensch={bg="transparent"},
    Galbrag={bg={100,255,50}},
    Ghourdal={bg={150,200,50}},
    Horpas={bg={200,150,50}},
    Wolf={bg={255,100,50}}
  })
  self:create_label("rage", {15, 45, 70, 20}, function(t) return t or "ruhig" end)
  self:add_label_states("rage", {
    [true]={bg={230,230,30}},
    [false]={bg="transparent"}
  })
  
  self:create_label("begleiter", {15, 75, 70, 20}, "Begleiter")
  self:add_label_states("begleiter", {
    [true]={bg={100,255,50}},
    [false]={bg="transparent"}
  })
  
  for _,label_ref in pairs(self.labels) do
    label_ref.object:setAlignment("c")
  end
  
  self.state.build = true
end

WerwolfGUI:init()
--##WerwolfGUI:init()</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>werwolf_gui_update_base</name>
--##				<packageName></packageName>
--##				<script>function werwolf_gui_update_base()
function werwolf_gui_update_base()
  if WerwolfGUI.hidden or not PLAYER.guild() or PLAYER.guild() == "werwoelfe" then
    return
  end
  WerwolfGUI:log(f"Hide because found guild is {PLAYER.guild()}")
  WerwolfGUI.containers["_BASE"]:hide()
  WerwolfGUI.hidden = true
end
--##end</script>
--##				<eventHandlerList>
--##					<string>gmcp.MG.char.base</string>
--##				</eventHandlerList>
--##			</Script>
--##		</ScriptGroup>
