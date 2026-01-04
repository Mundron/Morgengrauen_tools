--##		<Script isActive="yes" isFolder="no">
--##			<name>HR_misc</name>
--##			<packageName></packageName>
--##			<script>function Advent_days()
function Advent_days()
  if os.date("%m", os.time()) &lt; "12" then
    return 24
  end
  return math.min(24, tonumber(os.date("%d", os.time())))
end

function this_year()
  return os.date("%Y", os.time())
end

function get_year(delta)
  delta = delta or 0
  local result = f"{tonumber(this_year())+delta}"
  return result
end
--##end</script>
--##			<eventHandlerList />
--##		</Script>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>HintRegistryTemplate</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>HRT_init</name>
--##				<packageName></packageName>
--##				<script>HintRegistryTemplate = HintRegistryTemplate or MundronClassMethods:extend{
HintRegistryTemplate = HintRegistryTemplate or MundronClassMethods:extend{
  _name="HintRegistryTemplate",
  _module="HintRegistry",
  _version="1.0.0",
  files={profile={history={}}, game={targets={}, remap={}}},
  state={continue=false},
  limit=function() return math.inf end
}

function HintRegistryTemplate:new(init)
  -- test for asserted fields
  for _, field in pairs({"trigger", "prefix"}) do
    assert(
      table.get(init, {"config", field}),
      f"Missing field {field} for {init._name}"
    )
  end
  -- add file references
  for key, refs in pairs(self.files) do
    for field, default in pairs(refs) do
      table.set(init, {key, field}, default)
    end
  end
  return MundronClassMethods.new(self, init)
end

function HintRegistryTemplate:post_load_data()
  local pos_map = {}
  for _, target in pairs(self.data.targets) do
    for _, hint in pairs(target.hints) do
      pos_map[normalized_text(hint)] = target
    end
  end
  self.data.target_by_hint = pos_map
  self:info(f"{len(self.data.targets)} Ziele mit {len(pos_map)} Beschreibungen geladen.")
end

function HintRegistryTemplate:migrate_game(old_version)
  if old_version &lt; "1.0.0" then
    -- do nothing
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>HRT_misc</name>
--##				<packageName></packageName>
--##				<script>

function HintRegistryTemplate:reset()
  self.state.continue = 0
  self.temp = ""
  disableTrigger(self:name())
  disableTimer(self:name())
end

function HintRegistryTemplate:next_id()
  local position = len(self.data.targets)
  if position == 0 then
    return 1
  end
  return self.data.targets[position]._id + 1
end

function HintRegistryTemplate:progress(year)
  local done = 0
  year = year or this_year()
  for _, target in pairs(self.data.history[year]) do
    if target.done then
      done = done + 1
    end
  end
  local result = f"Fortschritt: {done} erledigt / " ..
    f"{len(self.data.history[year])} bekannt / {self.limit()} möglich"
  return result
end

function HintRegistryTemplate:trigger_hint()
  enableTrigger(self:name())
  send(self.config.trigger)
  disableTimer(self:name())
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>HRT_handle_input</name>
--##				<packageName></packageName>
--##				<script>function HintRegistryTemplate:handle_input(raw_input)
function HintRegistryTemplate:handle_input(raw_input)
  local clean_input, prefix = raw_input, self.config.prefix
  if raw_input == "&gt; " then
    self:analyze_hint()
    return
  end
  
  if len(prefix) &gt; 0 then
    if not string.find(raw_input, prefix) then
      -- false activated trigger!!!
      self:reset()
      return
    end
    clean_input = raw_input:gsub(prefix, "")
  end
  self.data.temp = f'{self.data.temp or ""}\n{clean_input}'
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>HRT_analyze_target</name>
--##				<packageName></packageName>
--##				<script>function HintRegistryTemplate:announce_text(known_target, new_target, target)
function HintRegistryTemplate:announce_text(known_target, new_target, target)
  local result = ""
  if known_target then
    result = f"Bereits gelistetes Ziel."
  else
    result = f"Neues Ziel fuer die Liste gefunden!"
  end
  result = f"{result}\n{self:progress()}"
  if new_target then
    result = f"{result}\nUnbekanntes Ziel! Id: {target._id}"
  else
    result = f"{result}\nBekanntes Ziel. Id: {target._id}"
  end
  return result
end

function HintRegistryTemplate:analyze_hint()
  local hint = self.data.temp
  local norm_hint = normalized_text(hint)
  local tytargets = table.get(self.data.history, this_year(), {})
  local target = self.data.target_by_hint[norm_hint]
  
  local change_to_save = false
  local text
  if target then
    -- there is such a target registered. But still have to check if it was seen this year!
    local seen=false
    for _, target_ref in pairs(tytargets) do
      if target_ref._id == target._id then
        seen = true
        break
      end
    end
    if not seen then
      table.insert(tytargets, {_id=target._id, done=false})
      change_to_save = true
    end
    text = self:announce_text(seen, false, target)
  else
    -- new hint, new target which was never tracked!
    local new_target = {_id=self:next_id(), hints={hint}, notes={}}
    table.insert(self.data.targets, new_target)
    table.insert(tytargets, {_id=new_target._id, done=false})
    self.data.target_by_hint[norm_hint] = new_target
    change_to_save = true
    text = self:announce_text(false, true, new_target)
  end
  self:info(text)
  
  if change_to_save then
    self:save_data()
  end
  --------------------------------------------------
  -- input processed. Ask for next target?
  --------------------------------------------------
  self.data.temp = ""
  self.state.continue = math.max(self.state.continue - 1, 0)
  if self.state.continue &gt; 0 and len(this_year) &lt; self.limit() then
    enableTimer(self:name())
  else
    self:reset()
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>HRT_display</name>
--##				<packageName></packageName>
--##				<script>function HintRegistryTemplate:show_targets(start_pos, end_pos, year)
function HintRegistryTemplate:show_targets(start_pos, end_pos, year)
  year = year or this_year()
  local history = table.get(self.data.history, year) or {}
  local size = len(history)
  start_pos = math.min(math.max(start_pos or 1, 1), size)
  end_pos = math.max(math.min(end_pos or size, size), 1)
  local limiter = string.rep("=", 50)
  local unknown = 0
  for i, target_ref in ipairs(history) do
    if target_ref._id &lt; 0 then
      unknown = unknown + 1
    end
    if i &gt;= start_pos and i &lt;= end_pos then
      print(limiter)
      print(self:single_target(target_ref._id))   
    end
  end
end

function HintRegistryTemplate:single_target(_id)
  local result = ""
  local border = string.rep("-", 50)
  for _,hint in pairs(self.data.targets[_id].hints) do
    result = f"{result}{hint}\n{border}"
  end
  return result
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>HRT_check_target</name>
--##				<packageName></packageName>
--##				<script>function HintRegistryTemplate:target_done(history_id)
function HintRegistryTemplate:target_done(history_id)
  self.data.history[history_id].done = true
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>ChristmasDoorRegistry</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>CDR_init</name>
--##				<packageName></packageName>
--##				<script>ChristmasDoorRegistry = ChristmasDoorRegistry or HintRegistryTemplate:new{
ChristmasDoorRegistry = ChristmasDoorRegistry or HintRegistryTemplate:new{
  _name = "ChristmasDoorRegistry",
  _shortname = "Tuerchen",
  _module = "HintRegistry",
  _version = "1.0.0",
  config = {
    prefix = "Der Weihnachtstroll sagt: ",
    trigger = "frage troll nach tuerchen"
  },
  limit = Advent_days
}

WT = ChristmasDoorRegistry

function ChristmasDoorRegistry:migrate_profile(old_version)
  if old_version &lt; "1.0.0" then
    -- do nothing
  end
end

function ChristmasDoorRegistry:migrate_game(old_version)
  if old_version &lt; "1.0.0" then
    -- do nothing
  end
end

--##</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>ChristmasThiefRegistry</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>CTR_init</name>
--##				<packageName></packageName>
--##				<script>ChristmasThiefRegistry = ChristmasThiefRegistry or HintRegistryTemplate:new{
ChristmasThiefRegistry = ChristmasThiefRegistry or HintRegistryTemplate:new{
  _name = "ChristmasThiefRegistry",
  _shortname = "Diebe",
  _module = "HintRegistry",
  _version = "1.0.0",
  config = {
    prefix = "Der Para-Weihnachtstroll sagt: ",
    trigger = "frage troll nach dieb"
  },
  limit = Advent_days
}

PWT = ChristmasThiefRegistry

function ChristmasThiefRegistry:migrate_profile(old_version)
  if old_version &lt; "1.0.0" then
    self.pmove("PWT_history", self:name("history"))
  end
end

function ChristmasThiefRegistry:migrate_game(old_version)
  if old_version &lt; "1.0.0" then
    self.mmove("PWT_remap", self:name("remap"))
    local targets = {}
    for _, target in pairs(self.mload("PWT_thieves")) do
      targets[target._id] = {
        _id = target._id,
        hints = target.descriptions,
        notes = {},
        npc_id = target.npc_id
      }
    end
    self.msave(targets, self:name("targets"))
    self.mremove("PWT_remap")
    self.mremove("PWT_thieves")
  end
end

--##</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>CTR_announcement</name>
--##				<packageName></packageName>
--##				<script>function ChristmasThiefRegistry:announce_text(known_target, new_target, target)
function ChristmasThiefRegistry:announce_text(known_target, new_target, target)
  local result = HintRegistryTemplate.announce_text(self, known_target, new_target, target)
  if target.npc_id then
    for _, npc in pairs(EK.data.npcs) do
      if npc._id == npc_id then
        result = f"{result}\nEK zugewiesen: {target.npc_id} - {npc.name} - {npc.ort} - {npc.region}"
        break  
      end
    end
  else
    result = f"{result}\nKein EK zugewiesen."
  end
  return result
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>EasterEggRegistry</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>EER_init</name>
--##				<packageName></packageName>
--##				<script>EasterEggRegistry = EasterEggRegistry or HintRegistryTemplate:new{
EasterEggRegistry = EasterEggRegistry or HintRegistryTemplate:new{
  _name = "EasterEggRegistry",
  _shortname = "Ostereier",
  _module = "HintRegistry",
  _version = "1.0.0",
  config = {
    prefix = "Der Osterhase sagt: ",
    trigger = "frage hase nach ei"
  },
  limit = Advent_days
}

EER = EasterEggRegistry

function EasterEggRegistry:migrate_profile(old_version)
  if old_version &lt; "1.0.0" then
    -- do nothing
  end
end

function EasterEggRegistry:migrate_game(old_version)
  if old_version &lt; "1.0.0" then
    -- do nothing
  end
end

--##</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>PotionRegistry</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>ZT_init</name>
--##				<packageName></packageName>
--##				<script>PotionRegistry = PotionRegistry or HintRegistryTemplate:new{
PotionRegistry = PotionRegistry or HintRegistryTemplate:new{
  _name = "PotionRegistry",
  _shortname = "ZT",
  _module = "HintRegistry",
  _version = "1.0.0",
  config = {
    prefix = "",
    trigger = "zaubertraenke"
  },
  limit = function() return 40 end
}

ZT = PotionRegistry
--##ZT = PotionRegistry</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>ZT_migration</name>
--##				<packageName></packageName>
--##				<script>function PotionRegistry:migrate_profile(old_version)
function PotionRegistry:migrate_profile(old_version)
  if old_version &lt; "1.0.0" then
    self:info("START")
    local history = {}
    for _, line in pairs(pload_csv("Zaubertraenke_History")) do
      local _id, _ = unpack(line)
      table.insert(history, {_id=_id, done=false})
    end
    self.psave({[this_year()]=history}, self:name("history"))
    premove_csv("Zaubertraenke_History")
    premove_tlines("Zaubertraenke_gefunden")
  end
end

function PotionRegistry:migrate_game(old_version)
  if old_version &lt; "1.0.0" then
    local potions = {}
    local _id = 1
    local flag = "meta"
    local hint, note = "", ""
    for _, line in pairs(mload_tlines("Zaubertraenke")) do
      if flag == "meta" then
        if not string.startswith(line, "ZT_") then
          hint = line
          flag = "hint"
        end
      elseif flag == "hint" then
        if len(line) &gt; 0 then
          hint = f"{hint}\n{line}"
        else
          flag = "note"
        end
      elseif flag == "note" then
        if string.startswith(line, "----------") then
          table.insert(potions, {
            _id = _id,
            hints = {hint},
            notes = {note}
          })
          _id = _id + 1
          hint, note = "", ""
          flag = "meta"
        else
          note = f"{note}\n{line}"
        end
      end
    end
    self.msave(potions, self:name("targets"))
    mremove_tlines("Zaubertraenke")
  end
end

--##</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>ZT_post_load</name>
--##				<packageName></packageName>
--##				<script>function PotionRegistry:post_load_data()
function PotionRegistry:post_load_data()
  HintRegistryTemplate.post_load_data(self)
  local history = self.data.history
  if len(history) == 0 then
    return
  elseif len(history) &gt; 1 then
    self:error("Zaubertrank History läuft über mehrere Jahre!")
  end
  local hyear, tyear = table.keys(history)[1], this_year()
  if hyear == tyear then
    return
  end
  history[tyear] = history[hyear]
  history[hyear] = nil
  self:info(f"Zaubertranke vom Jahr {hyear} nach {tyear} übertragen")
  self:save_profile()
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
