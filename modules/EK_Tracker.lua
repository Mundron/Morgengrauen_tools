--##		<Script isActive="yes" isFolder="no">
--##			<name>EK_init</name>
--##			<packageName></packageName>
--##			<script>EK = EK or MundronClassMethods:new{
EK = EK or MundronClassMethods:new{
  _name = "EK",
  _shortname = "EK",
  _module = "EK_Tracker",
  _version = "1.0.0",
  config = {tracking = true},
  data = {
    player_hasnt = -1, 
    competitor_hasnt = -1
  },
  files = {
    profile = {
      known_kills = {}, 
      unknown_kills = 0, 
      competitions={}
    },
    game = {
      npcs={}
    }
  }
}
  
function EK:post_load_data()
  self:info(f"{len(self.data.npcs)} NPCs und {len(self.data.known_kills)} Kills geladen")
end
--##end</script>
--##			<eventHandlerList />
--##		</Script>
--##		<Script isActive="yes" isFolder="no">
--##			<name>EK_helpers</name>
--##			<packageName></packageName>
--##			<script>------------------------------------------------------
------------------------------------------------------
--
------------------------------------------------------

function EK:kill_count()
  return len(self.data.known_kills) + self.data.unknown_kills
end

------------------------------------------------------
--
------------------------------------------------------

function EK:print_npc(position, npc)
  if not npc then
    eprint("Unzulaessiger NPC zur Anzeige uebergeben.", "EK-Tracker")
    display(npc)
    return
  end
  if len(npc) == 0 then
    iprint("Kein NPC gefunden.", "EK-Tracker")
    return
  end
  local ort = "Ort"
  local world = tonumber(npc["para"]) or 0
  ort = ort .. "(" .. world .. "):"
  if world &gt; 0 then
    ort = "&lt;255,255,0:0,0,0&gt;" .. ort
  else
    ort = "&lt;0,255,0:0,0,0&gt;" .. ort
  end
  local npc_table =
    {
      {
        "&lt;0,255,0:0,0,0&gt;Nr:",
        "&lt;0,255,0:0,0,0&gt;Name:",
        ort,
        "&lt;0,255,0:0,0,0&gt;Region:",
        "&lt;0,255,0:0,0,0&gt;Magier:",
      },
      {
        npc["position"] or "",
        npc["name"] or "",
        npc["ort"] or "",
        npc["region"] or "",
        npc["magier"] or "",
      },
    }
  table.insert(npc_table[1], "&lt;0,255,0:0,0,0&gt;Hinweis:")
  local hintlines = break_lines(npc["hinweis"] or "")
  table.insert(npc_table[2], hintlines[1])
  for i = 2, len(hintlines) do
    table.insert(npc_table[1], "")
    table.insert(npc_table[2], hintlines[i])
  end
  if npc.ek then
    table.insert(npc_table[1], "&lt;0,255,0:0,0,0&gt;Geholt:")
    local kill = self.data.known_kills[npc._id]
    if not kill then
      table.insert(npc_table[2], "&lt;255,0,0:0,0,0&gt;Nein")
    else
      if kill.date == 0 then
        table.insert(npc_table[2], "unbekannt")
      else
        table.insert(npc_table[2], os.date("%d.%m.%y", kill.date))
      end
    end
  else
    table.insert(npc_table[1], "&lt;255,255,0:0,0,0&gt;Kein EK")
    table.insert(npc_table[2], "")
  end
  echo("\n")
  print_table(norm_table(npc_table, -1, 1))
end

------------------------------------------------------
--
------------------------------------------------------

function EK:print_npc_list(npcs, prop, no_killer)
  if len(npcs) == 0 then
    iprint("Keine NPCs gefunden.", "EK-Tracker")
    return
  end
  local npc_table = {{}, {}, {}, {}}
  prop = prop or "ort"
  positions = table.keys(npcs)
  table.sort(positions)
  for _, position in pairs(positions) do
    local npc = npcs[position]
    local kill = self.data.known_kills[npc._id]
    if no_killer or (kill and kill.date &gt; -1) then
      position = "&lt;0,255,0:0,0,0&gt;" .. position
    else
      position = "&lt;255,255,0:0,0,0&gt;" .. position
    end
    local prop_title = string.title(prop)
    if prop == "ort" then
      prop_title = prop_title .. "(" .. npc["para"] .. "):"
      if npc["para"] &gt; 0 then
        prop_title = "&lt;255,200,0:0,0,0&gt;" .. prop_title
      else
        prop_title = "&lt;0,255,0:0,0,0&gt;" .. prop_title
      end
    else
      prop_title = "&lt;0,255,0:0,0,0&gt;" .. prop_title
    end
    table.insert(npc_table[1], position)
    table.insert(npc_table[2], npc["name"]:sub(1, 30))
    table.insert(npc_table[3], prop_title)
    table.insert(npc_table[4], npc[prop]:sub(1, 30))
  end
  echo("\n")
  print_table(norm_table(npc_table, {1, -1, -1, -1}, 1))
end

------------------------------------------------------
--
------------------------------------------------------

function EK:num_plus_diff(base, reference)
  if type(reference) == "nil" then
    return {tostring(base), "", ""}
  end
  local difference = base - reference
  local sign = "+"
  local diff_color = "&lt;0,255,0:0,0,0&gt;"
  if difference &lt; 0 then
    sign = ""
    -- don't change to "-", because the negative value has already the sign
    diff_color = "&lt;255,255,0:0,0,0&gt;"
  end
  return {tostring(base), diff_color, "(" .. sign .. difference .. ")"}
end
--##end</script>
--##			<eventHandlerList />
--##		</Script>
--##		<Script isActive="yes" isFolder="no">
--##			<name>EK_list_handling</name>
--##			<packageName></packageName>
--##			<script>------------------------------------------------------
------------------------------------------------------
--
------------------------------------------------------

function EK:missing()
  local npcs = {}
  for position, npc in ipairs(self.data.npcs) do
    if not self.data.known_kills[npc._id] then
      npcs[position] = npc
    end
  end
  self:print_npc_list(npcs, "ort", false)
  iprint({"Es sind", {len(npcs), "ly"}, "fehlende EKs eingetragen."}, "EK-Tracker")
end

------------------------------------------------------
--
------------------------------------------------------
function EK:find_by_id(search_id)
  local npc = self.data.npcs[search_id]
  self:print_npc(search_id, npc)
end

function EK:find_by_range(start_id, end_id, prop_filter)
  if start_id &gt; end_id then
    eprint("Start ID muss kleiner sein als End ID.", "EK-Tracker")
    return
  end
  local npcs = {}
  for position, npc in ipairs(self.data.npcs) do
    if start_id &lt;= npc.position and npc.position &lt;= end_id then
      npcs[position] = npc
    end
  end
  self:print_npc_list(npcs, prop_filter)
end

function EK:find_by_prop(pattern_dict)
  local npcs = {}
  for position, npc in ipairs(self.data.npcs) do
    npc_condition = true
    for attr, value in pairs(pattern_dict) do
      if not substring(string.lower(npc[attr]), string.lower(value)) then
        npc_condition = false
        break
      end
    end
    if npc_condition then
      npcs[position]= npc
    end
  end
  self:print_npc_list(npcs)
  return npcs
end


------------------------------------------------------
--
------------------------------------------------------

function EK:check(nr, date, overwrite)
  local npc = self.data.npcs[nr]
  if npc == nil then
    eprint({"Kein NPC mit der Nummer ", {id, "y"}, " gefunden."}, "EK-Tracker")
    return
  end
  local kill = self.data.known_kills[npc._id]
  if kill then
    if overwrite then
      if date then
        local d, m, y = date:match("(%d+)\.(%d+)\.(%d+)")
        kill.date = os.time({year = 2000 + y, month = m, day = d})
      else
        kill.date = os.time()
      end
      iprint({"EK mit der Nummer ", {nr, "y"}, " hat Datumskorrektur erhalten."}, "EK-Tracker")
    else
      wprint("EK bereits erworben! Zum Ueberschreiben -f benutzen.", "EK-Tracker")
    end
  else
    if date then
      if string.lower(date) == "x" then
        date = 0
      else
        local d, m, y = date:match("(%d+)\.(%d+)\.(%d+)")
        date = os.time({year = 2000 + y, month = m, day = d})
      end
    else
      date = os.time()
    end
    self.data.known_kills[npc._id] = {name=npc.name, date=date, _id=npc._id}
    self:save_data()
    iprint({"EK mit der Nummer ", {nr, "y"}, " ist nun abgehakt."}, "EK-Tracker")
    if EK.config.plaketten_lesen then
      send("lies plakette")
    else
      MainGUI.ekanzahl:echo("EK-Anzahl: " .. self:kill_count(), "black")
    end
  end
end

------------------------------------------------------
--
------------------------------------------------------

function EK:uncheck(nr)
  local npc = self.data.npcs[nr]
  if npc == nil then
    eprint({"Kein NPC mit der Nummer ", {nr, "y"}, " gefunden."}, "EK-Tracker")
    return
  end
  if self.data.known_kills[npc._id] then
    self.data.known_kills[npc._id] = nil
    self:save_kills()
    iprint({"Der EK mit der Nummer ", {nr, "y"}, " ist nun nicht mehr abgehakt."}, "EK-Tracker")
  else
    wprint("Der EK wurde noch nicht erworben.", "EK-Tracker")
    return
  end
  if self.data.plaketten_lesen then
    send("lies plakette")
  else
    MainGUI.ekanzahl:echo("EK-Anzahl: " .. self:kill_count(), "black")
  end
end

------------------------------------------------------
--
------------------------------------------------------


function EK:add(name, place, region, creator, hint, world, nonkillpoints)
  if not name then
    eprint("Der Eintrag muss wenigstens einen Namen haben.", "EK-Tracker")
  end
  max_id = -1
  for _, npc in pairs(self.data.npcs) do
    max_id = math.max(next_id, npc._id)
  end
  local doc = {name = name, _id = max_id + 1}
  local function add(field, value)
    if value and len(value) &gt; 0 then
      doc[field] = value
    end
  end
  add("ort", place)
  add("region", region)
  add("magier", creator)
  add("hinweis", hint)
  doc["para"] = world or 0
  doc["ek"] = not nonkillpoints
  table.insert(self.data.npcs, doc)
  iprint({{"Neu eingetragener EK:", "y"}}, "EK-Tracker")
  self:print_npc(len(self.data.npcs), doc)
  self:save_game()
end

------------------------------------------------------
--
------------------------------------------------------

function EK:find_attr(attr, sub)
  local matches = {}
  local _attr = string.lower(attr)
  local _sub = string.lower(sub)
  for _, npc in pairs(self.data.npcs) do
    if npc[_attr] and substring(string.lower(npc[_attr]), _sub) then
      matches[npc[_attr]] = true
    end
  end
  if len(matches) == 0 then
    iprint("Keine " .. string.title(attr) .. " gefunden.", "EK-Tracker")
  else
    matches = table.keys(matches)
    table.sort(matches)
    iprint("Zum '" .. attr .. "' mit '" .. sub .. "' gefunden:", "EK-Tracker")
    for i, v in ipairs(matches) do
      decho("&lt;0,255,0:0,0,0&gt;" .. i .. ": ")
      echo(v .. "\n")
    end
    echo("\n")
  end
end

------------------------------------------------------
--
------------------------------------------------------

function EK:unknown(x)
  if not x then
    iprint(
      {"Die Anzahl unbekannter EKs ist ", {self.data.unknown_kills, "&lt;0,255,0:0,0,0&gt;"}, "."},
      "EK-Tracker"
    )
    return
  end
  local ausgabe =
    {
      "Die Anzahl unbekannter EKs aendert sich von ",
      {self.data.unknown_kills, "&lt;0,255,0:0,0,0&gt;"},
      " zu ",
    }
  self.data.unknown_kills = self.data.unknown_kills + x
  table.insert(ausgabe, {self.data.unknown_kills, "&lt;0,255,0:0,0,0&gt;"})
  table.insert(ausgabe, ".")
  self:save_data()
  iprint(ausgabe, "EK-Tracker")
  if self.config.plaketten_lesen then
    send("lies plakette")
  else
    MainGUI.ekanzahl:echo("EK-Anzahl: " .. self:kill_count(), "black")
  end
end

------------------------------------------------------
--
------------------------------------------------------

function EK:zeige(von, bis)
  if von then
    local d, m, y = von:match("(%d+)\.(%d+)\.(%d+)")
    von = os.time({year = 2000 + y, month = m, day = d})
  else
    von = 0
  end
  if bis then
    -- we like to get all kill entries even
    -- for the chosen day. So, the upper limit
    -- has to be extended for a day
    local d, m, y = bis:match("(%d+)\.(%d+)\.(%d+)")
    bis = os.time({year = 2000 + y, month = m, day = d}) + 24 * 60 * 60
  else
    bis = os.time() + 24 * 60 * 60
  end
  local npcs = {}
  for position, npc in ipairs(self.data.npcs) do
    date = (self.data.known_kills[npc._id] or {}).date
    if date and von &lt;= date and date &lt;= bis then
      npcs[position] = npc
    end
  end
  self:print_npc_list(npcs)
  iprint({"Es wurden ", {len(npcs), "y"}, " NPCs gefunden."}, "EK-Tracker")
end

------------------------------------------------------
--
------------------------------------------------------

function EK:delete(nr)
  if self.state.del_flag and self.state.del_flag.nr == nr then
    table.remove(self.data.npcs, nr)
    for pos, npc in ipairs(self.data.npcs) do
      if pos &gt;= nr then
        npc.position = pos
      end
    end
    self.state.del_flag = nil
    self:save_game()
    iprint("Der EK wurde geloescht.", "EK-Tracker")
  else
    local npc = self.data.npcs[nr]
    if not npc then
      iprint("Es wurde kein NPC mit der Nummer " .. nr .. " gefunden.", "EK-Tracker")
      return
    end
    iprint(
      "Moechtest du folgenden EK aus der Liste loeschen? Falls ja, wiederhole den Befehl!",
      "EK-Tracker"
    )
    self:print_npc(nr, npc)
    self.state.del_flag = {nr = nr}
  end
end

------------------------------------------------------
--
------------------------------------------------------

function EK:sort(old_nr, new_nr)
  if old_nr &lt; 1 or old_nr &gt; len(self.data.npcs) or new_nr &lt; 1 or new_nr &gt; len(self.data.npcs) then
    eprint("Unzulaessige Positionen " .. old_nr .. " oder " .. new_nr .. ".", "EK-Tracker")
    return
  end
  local temp = self.data.npcs[old_nr]
  if old_nr &gt; new_nr then
    for i = old_nr, new_nr + 1, -1 do
      self.data.npcs[i] = self.data.npcs[i - 1]
      self.data.npcs[i].position = i
    end
  else
    for i = old_nr, new_nr - 1, 1 do
      self.data.npcs[i] = self.data.npcs[i + 1]
      self.data.npcs[i].position = i
    end
  end
  temp.position = new_nr
  self.data.npcs[new_nr] = temp
  self:save_game()
  iprint(
    "Der NPC an der Stelle " .. old_nr .. " wurde nun an die Stelle " .. new_nr .. " gesteckt.",
    "EK-Tracker"
  )
end

------------------------------------------------------
--
------------------------------------------------------

function EK:change(nr, attr, content)
  local position = tonumber(nr)
  attr = string.lower(attr)
  if not position then
    eprint({"Die Eingabe", {nr, "y"}, "ist keine Zahl."}, "EK-Tracker")
    return
  end
  if self.state.change_flag and self.state.change_flag.npc.position == position then
    self.state.change_flag.npc[attr] = self.state.change_flag.change
    echo("\nDas Attribut ")
    decho("&lt;0,255,0:0,0,0&gt;" .. string.title(attr))
    echo(" wurde zu \n")
    decho("&lt;0,255,0:0,0,0&gt;" .. content)
    echo("\ngeaendert.\n\n")
    self:print_npc(self.state.change_flag.position, self.state.change_flag.npc)
    self.state.change_flag = nil
    self:save_game()
  else
    if attr == "para" then
      local num = tonumber(content)
      if num and num &gt; -1 then
        content = num
      else
        eprint(
          "Die Welt/Parallelwelt muss eine ganze Zahl groesser oder gleich 0 sein.", "EK-Tracker"
        )
      end
    end
    local npc = self.data.npcs[nr]
    if npc == nil then
      iprint({"Es konnte kein NPC mit der ID", {id, "y"}, "gefunden werden."}, "EK-Tracker")
      return
    end
    echo("Willst du bei ...\n\n")
    self:print_npc(nr, npc)
    echo("\n... wirklich das Attribut ")
    decho("&lt;0,255,0:0,0,0&gt;" .. string.title(attr))
    echo(" zu \n")
    decho("&lt;0,255,0:0,0,0&gt;" .. content)
    echo("\naendern? Falls ja, dann wiederhole den Befehl.\n\n")
    self.state.change_flag = {npc = npc, position=nr, change = content}
  end
end

------------------------------------------------------
--
------------------------------------------------------

function EK:multichange(ids, attr, content)
  attr = string.lower(attr)
  if self.state.mchange_flag and self.state.mchange_flag.ids == ids then
    for _, npc in pairs(self.state.mchange_flag.npcs) do
      npc[attr] = self.state.mchange_flag.change
    end
    echo("\nDas Attribut ")
    decho("&lt;0,255,0:0,0,0&gt;" .. string.title(attr))
    echo(" wurde zu \n")
    decho("&lt;0,255,0:0,0,0&gt;" .. content)
    echo("\ngeaendert:\n")
    self:print_npc_list(self.state.mchange_flag.npcs, attr)
    self.state.mchange_flag = nil
    self:save_game()
  else
    if attr == "para" then
      local num = tonumber(content)
      if num and num &gt; -1 then
        content = num
      else
        eprint(
          "Die Welt/Parallelwelt muss eine ganze Zahl groesser oder gleich 0 sein.", "EK-Tracker"
        )
      end
    end
    local id_list = {}
    for von, bis in ids:gmatch("(%d+) bis (%d+)") do
      for i = von, bis, 1 do
        table.insert(id_list, i)
      end
    end
    shorten_ids = ids:gsub("(%d+) bis (%d+)", "")
    for id in shorten_ids:gmatch("%d+") do
      table.insert(id_list, tonumber(id))
    end
    local npcs = {}
    for _, id in pairs(id_list) do
      npcs[id] = self.data.npcs[id]
    end
    if len(npcs) == 0 then
      iprint({"Es konnte kein NPCs mit den IDs", {ids, "y"}, "gefunden werden."}, "EK-Tracker")
      return
    end
    echo("Willst du bei ...\n\n")
    self:print_npc_list(npcs, attr)
    echo("\n... wirklich das Attribut ")
    decho("&lt;0,255,0:0,0,0&gt;" .. string.title(attr))
    echo(" zu \n")
    decho("&lt;0,255,0:0,0,0&gt;" .. content)
    echo("\naendern? Falls ja, dann wiederhole den Befehl.\n\n")
    self.state.mchange_flag = {ids = ids, npcs = npcs, change = content}
  end
end
--##end</script>
--##			<eventHandlerList />
--##		</Script>
--##		<Script isActive="yes" isFolder="no">
--##			<name>EK_plaketten_handling</name>
--##			<packageName></packageName>
--##			<script>------------------------------------------------------
------------------------------------------------------
--
------------------------------------------------------

function EK:save_plakettenabgleich(name)
  echo(
    "\n\nCompetitor: " ..
    name ..
    " is missing " ..
    self.data.player_hasnt ..
    " and has " ..
    self.data.competitor_hasnt ..
    "\n\n"
  )
  if self.data.player_hasnt &gt; -1 and self.data.competitor_hasnt &gt; -1 then
    name = name:lower()
    table.insert(
      self.data.competitions,
      {
        player_count = self:kill_count(),
        player_hasnt = self.data.player_hasnt,
        date = os.time(),
        competitor_name = name,
        competitor_count = self:kill_count() - self.data.competitor_hasnt + self.data.player_hasnt,
        competitor_hasnt = self.data.competitor_hasnt,
      }
    )
    self.data.player_hasnt = -1
    self.data.competitor_hasnt = -1
    self:save_data()
    self:show_friend(name)
  end
end

------------------------------------------------------
--
------------------------------------------------------

function EK:del_abgleich(nr)
  if nr &lt; 1 or nr &gt; len(self.data.competitions) then
    eprint("Ungueltige Nummer " .. nr .. ".", "EK-Tracker")
    return
  end
  if self.state.pdel_flag and self.state.pdel_flag.nr == nr then
    table.remove(self.data.competitions, nr)
    self.state.pdel_flag = nil
    self:save_data()
    iprint("Plakettenvergleichseintrag geloescht.", "EK-Tracker")
  else
    iprint({"Willst du wirklich den Eintrag mit der Nummer ", {nr, "y"}, "loeschen?"}, "EK-Tracker")
    self:show_friend(nr)
    iprint("Falls ja, dann wiederhole den Befehl.", "EK-Tracker")
    self.state.pdel_flag = {nr = nr}
  end
end

------------------------------------------------------
--
------------------------------------------------------

function EK:show_friend(arg)
  local entries = {}
  local name = arg
  if type(arg) == "number" then
    if arg &lt; 1 or arg &gt; len(self.data.competitions) then
      eprint("Ungueltige Nummer " .. nr .. ".", "EK-Tracker")
      return
    end
    entries = {self.data.competitions[arg]}
    entries[1]._row_id = arg
    if len(entries) &gt; 0 then
      name = string.title(entries[1]["competitor_name"])
    end
  else
    arg = string.lower(arg)
    local cnt = 3
    local entry
    for i = len(self.data.competitions), 1, -1 do
      entry = self.data.competitions[i]
      if entry.competitor_name == arg then
        entry._row_id = i
        table.insert(entries, 1, entry)
        cnt = cnt - 1
      end
      if cnt == 0 then
        break
      end
    end
  end
  if len(entries) == 0 then
    iprint("Es wurden keine Eintraege gefunden.", "EK-Tracker")
    return
  end
  echo("\n\n")
  local tab = {}
  table.insert(
    tab,
    norm_length(
      {
        "ID:",
        "",
        "",
        "",
        "Deine EKs:",
        "EKs von " .. name .. ":",
        "Dir fehlen:",
        name .. " fehlen:",
      },
      1
    )
  )
  local previous_entry = {}
  local keys = {"player_count", "competitor_count", "player_hasnt", "competitor_hasnt"}
  for _, entry in pairs(entries) do
    local date = os.date("%d.%m.%y", entry["date"])
    local time = os.date("%H:%M", entry["date"])
    local values = {}
    local max_diff_len = 0
    for _, key in pairs(keys) do
      table.insert(values, EK:num_plus_diff(entry[key], previous_entry[key]))
      max_diff_len = math.max(max_diff_len, #values[#values][3])
    end
    for i, v in pairs(values) do
      local spaces = " "
      for _ = 1, max_diff_len - #v[3], 1 do
        spaces = spaces .. " "
      end
      values[i] = v[1] .. spaces .. v[2] .. v[3]
    end
    table.insert(
      tab,
      norm_length({entry["_row_id"] .. " ", date .. " ", time .. " ", "", unpack(values)}, 1, 2)
    )
    previous_entry = entry
  end
  print_table(tab)
  echo("\n")
end
--##end</script>
--##			<eventHandlerList />
--##		</Script>
--##		<Script isActive="yes" isFolder="no">
--##			<name>EK_no_badge_for_small_players</name>
--##			<packageName></packageName>
--##			<script>function EK_no_badge_for_small_players()
function EK_no_badge_for_small_players()
  -- nicht-Seher haben eh keine Plakette und damit muessen
  -- Spielanfaenger erstmal sich nicht um diese
  -- Einstellung kuemmern
  EK.config.plakette_lesen = gmcp.MG.char.base.wizlevel ~= 0
end
--##end</script>
--##			<eventHandlerList>
--##				<string>gmcp.MG.char.base</string>
--##			</eventHandlerList>
--##		</Script>
--##		<Script isActive="yes" isFolder="no">
--##			<name>EK_migration</name>
--##			<packageName></packageName>
--##			<script>function EK:migrate_game(saved_version)
function EK:migrate_game(saved_version)
  if saved_version &lt; "1.0.0" then
    local npcs = mload_jsonl("EK_NPC_liste")
    msave_json(npcs, self:name("npcs"))
    mremove_jsonl("EK_NPC_liste")
    self:info(f"Migration von Spieldaten auf Version 1.0.0 mit {len(npcs)} NPCs erledigt")
  end
end

function EK:migrate_profile(saved_version)
  if saved_version &lt; "1.0.0" then
    pmove_json("EK_pwt_diebe_trace", self:name("diebe.trace"))
    local competitions = pload_jsonl("EK_Plakettenvergleich")
    psave_json(competitions, self:name("competitions"))
    premove_jsonl("EK_Plakettenvergleich")
    
    local kills = pload_jsonl("EK_Kills")
    local new_kills = {}
    local unknown_kills = 0
    for _, kill in pairs(kills) do
      if kill._id then
        new_kills[kill._id] = kill
      else
        unknown_kills = unknown_kills + 1
      end
    end
    psave_json(new_kills, self:name("known_kills"))
    psave_json(unknown_kills, self:name("unknown_kills"))
    premove_jsonl("EK_Kills")
    self:info("Migration von Profildaten auf Version 1.0.0 mit {len(new_kills)} bekannten und {unknown_kills} unbekannten Kills erledigt")
  end
end
--##end</script>
--##			<eventHandlerList />
--##		</Script>
