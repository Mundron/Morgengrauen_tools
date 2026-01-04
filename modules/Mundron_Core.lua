--##		<Script isActive="yes" isFolder="no">
--##			<name>MC_init_colors</name>
--##			<packageName></packageName>
--##			<script>function MC_init_colors()
function MC_init_colors()
  return farben or  {
    vg = {
      komm = "cyan", 
      ebenen = "red", 
      info = "green", 
      alarm = "white", 
      script = "dark_green"
    },
    bg = {
      komm = "black", 
      ebenen = "black", 
      info = "black", 
      alarm = "red", 
      script = "black"
    },
  }
end

farben = MC_init_colors()
--##farben = MC_init_colors()</script>
--##			<eventHandlerList />
--##		</Script>
--##		<Script isActive="yes" isFolder="no">
--##			<name>misc</name>
--##			<packageName></packageName>
--##			<script>function log(text)
function log(text)
  local timestamp = os.date("%Y-%m-%d#%H-%M", os.time())
  local file = io.open(getProfileDataPath("debug.log"), "a")
  file:write(f"{timestamp} - {text}\n")
  file:close()
end

function len(obj)
  if type(obj) == "string" then
    return string.len(obj)
  elseif type(obj) == "table" then
    return table.size(obj)
  else
    return 0
  end
end
--##end</script>
--##			<eventHandlerList />
--##		</Script>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>helper_functions</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>json_helper</name>
--##				<packageName></packageName>
--##				<script>--[[
--[[
  Converter of serializable Lua objects to JSON strings and backwards
  Usage:
  json.encode_oneline({42, 23, 12}) --&gt; "[42, 23, 12]"
  json.encode({42, 23, 12}) --&gt;
  [
    42,
    23,
    12
  ]
  json.decode('{"apple": 13, "tree": true}') --&gt; {["apple"] = 13, ["tree"] = true}
]]--

json = {
  _version = "1.0.0",
  _author = "Mundron",
  _contact = "https://github.com/Mundron",
  _repository = "https://github.com/Mundron/Morgengrauen_tools"
}

local escape_char_map = {
  ["/"] = "\\/",
  ['"'] = '\\"',
  ["\b"] = "\\b",
  ["\f"] = "\\f",
  ["\n"] = "\\n",
  ["\r"] = "\\r",
  ["\t"] = "\\t",
}

local escape_char_map_inv = {["\\\\"]="\\"}
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end

local function escaped_string(value)
  -- Escape backslash first to avoid double-escaping
  value = value:gsub("\\", "\\\\")
  for k, v in pairs(escape_char_map) do
    if k ~= "\\" then  -- Already handled
      value = value:gsub(k, v)
    end
  end
  return '"' .. value .. '"'
end

local function isArray(value)
  local count = 0
  for k, v in pairs(value) do
    count = count + 1
    if type(k) ~= "number" or k ~= count then
      return false
    end
  end
  return true
end

function json.encode(value, indent)
  indent = indent or 0
  local indentStr = string.rep("  ", indent)
  local nextIndentStr = string.rep("  ", indent + 1)
    
  local valueType = type(value)
  if value == nil then
    return "null"
  elseif valueType == "boolean" then
    return tostring(value)
  elseif valueType == "number" then
    return tostring(value)
  elseif valueType == "string" then
    return escaped_string(value)        
  end
  
  if valueType == "table" then
    if isArray(value) then
      if #value == 0 then
        return "[]"
      else
        local parts = {}
        for i = 1, #value do  -- FIX: was using undefined 'count'
          table.insert(parts, nextIndentStr .. json.encode(value[i], indent + 1))
        end
        return "[\n" .. table.concat(parts, ",\n") .. "\n" .. indentStr .. "]"
      end
    else
      local parts = {}
      for k, v in pairs(value) do
        local key
        if type(k) == "string" then
          key = escaped_string(k)
        elseif type(k) == "number" then
          key = f'"{k}"'
        else
          error(f"Invalid key type: {type(k)}")
        end
        table.insert(parts, f"{nextIndentStr}{key}: {json.encode(v, indent + 1)}")
      end
      -- Sort for consistent output
      table.sort(parts)
      return "{\n" .. table.concat(parts, ",\n") .. "\n" .. indentStr .. "}"
    end
  end
  
  error("Unsupported type: " .. valueType)
end

function json.encode_oneline(value)
  local result = json.encode(value)
  result = result:gsub("[\r\n]+", "")
  return result
end

-- JSON to Lua table parser
function json.decode(str)
  local pos, error_flag = 1, false
  
  local function decode_error(msg)
    printError(f"JSON decode error at position {pos}: {msg} - {str:sub(pos-10,pos+10)}", true, true)
    error_flag = true
  end
  
  local whitespace = {" ", "\t", "\n", "\r"}
  
  local function skip_whitespace()
    while table.contains(whitespace, str:sub(pos, pos)) and pos &lt;= #str do
      pos = pos + 1
    end
  end
  
  local function parse_string()
    if str:sub(pos, pos) ~= '"' then
      decode_error("Expected string")
    end
    pos = pos + 1  -- Skip opening quote
    
    local result = {}
    while pos &lt;= #str do
      local c = str:sub(pos, pos)
      
      if c == '"' then
        pos = pos + 1  -- Skip closing quote
        return table.concat(result)
      elseif c == "\\" then
        -- Handle escape sequences
        local escape = str:sub(pos, pos + 1)
        if escape_char_map_inv[escape] then
          table.insert(result, escape_char_map_inv[escape])
          pos = pos + 2
        elseif str:sub(pos + 1, pos + 1) == "u" then
          -- Unicode escape \uXXXX - simplified handling
          local hex = str:sub(pos + 2, pos + 5)
          local codepoint = tonumber(hex, 16)
          if codepoint then
            table.insert(result, string.char(codepoint))
          end
          pos = pos + 6
        else
          decode_error("Invalid escape sequence")
        end
      else
        table.insert(result, c)
        pos = pos + 1
      end
    end
    
    decode_error("Unterminated string")
  end -- function parse_string
  
  local function parse_number()
    local start_pos = pos
    local has_decimal = false
    local has_exponent = false
    
    -- Optional minus sign
    if str:sub(pos, pos) == "-" then
      pos = pos + 1
    end
    
    -- Digits before decimal point
    if not str:sub(pos, pos):match("%d") then
      decode_error("Invalid number")
    end
    
    while pos &lt;= #str and str:sub(pos, pos):match("%d") do
      pos = pos + 1
    end
    
    -- Optional decimal part
    if pos &lt;= #str and str:sub(pos, pos) == "." then
      has_decimal = true
      pos = pos + 1
      if not str:sub(pos, pos):match("%d") then
        decode_error("Invalid number")
      end
      while pos &lt;= #str and str:sub(pos, pos):match("%d") do
        pos = pos + 1
      end
    end
    
    -- Optional exponent
    if pos &lt;= #str and (str:sub(pos, pos) == "e" or str:sub(pos, pos) == "E") then
      has_exponent = true
      pos = pos + 1
      if str:sub(pos, pos) == "+" or str:sub(pos, pos) == "-" then
        pos = pos + 1
      end
      if not str:sub(pos, pos):match("%d") then
        decode_error("Invalid number")
      end
      while pos &lt;= #str and str:sub(pos, pos):match("%d") do
        pos = pos + 1
      end
    end
    
    return tonumber(str:sub(start_pos, pos - 1))
  end -- function parse_number
  
  local function parse_value()
    skip_whitespace()
    
    local c = str:sub(pos, pos)
    
    if str:sub(pos, pos + 3) == "null" then
      pos = pos + 4
      return nil
    elseif str:sub(pos, pos + 3) == "true" then
      pos = pos + 4
      return true
    elseif str:sub(pos, pos + 4) == "false" then
      pos = pos + 5
      return false
    elseif c == '"' then
      return parse_string()
    elseif c == "-" or c:match("%d") then
      return parse_number()
    elseif c == "[" then
      pos = pos + 1
      skip_whitespace()
      
      local arr = {}
      
      -- Empty array
      if str:sub(pos, pos) == "]" then
        pos = pos + 1
        return arr
      end
      
      while pos &lt;= #str do
        table.insert(arr, parse_value())
        skip_whitespace()
        
        local next_char = str:sub(pos, pos)
        if next_char == "]" then
          pos = pos + 1
          return arr
        elseif next_char == "," then
          pos = pos + 1
          skip_whitespace()
        else
          decode_error("Expected ',' or ']' in array")
        end
      end
    end
    
    -- object
    if c == "{" then
      pos = pos + 1
      skip_whitespace()
      
      local obj = {}
      
      -- Empty object
      if str:sub(pos, pos) == "}" then
        pos = pos + 1
        return obj
      end
      
      while pos &lt;= #str do
        skip_whitespace()
        
        -- Parse key
        local key = parse_value()
        skip_whitespace()
        
        if str:sub(pos, pos) ~= ":" then
          decode_error("Expected ':' after object key")
        end
        pos = pos + 1
        
        -- Parse value
        obj[key] = parse_value()
        skip_whitespace()
        
        local next_char = str:sub(pos, pos)
        if next_char == "}" then
          pos = pos + 1
          return obj
        elseif next_char == "," then
          pos = pos + 1
        else
          decode_error("Expected ',' or '}' in object")
        end
      end -- while
    end -- object parsing
    
    decode_error("Unexpected character: " .. c)
  end -- function parse_value
  
  local result = parse_value()
  skip_whitespace()
  
  if pos &lt;= #str then
    decode_error("Unexpected content after JSON value")
  end
  
  return result
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>pathes_helper</name>
--##				<packageName></packageName>
--##				<script>-------------------------------------------------
-------------------------------------------------
--         Put your Lua functions here.        --
--                                             --
-- Note that you can also use external scripts --
-------------------------------------------------


function getRepoPath(extension)
  local path_table = string.split(getModulePath("Mundron_Core"), "/")
  local result = table.concat(path_table, "/", 1, #path_table - 2)
  if extension then
    result = f"{result}/{extension}"
  end
  return result
end

function getRepoDataPath(extension)
  local result = getRepoPath(f"data")
  if not io.exists(result) then
    lfs.mkdir(result)
  end
  if extension then
    result = f"{result}/{extension}"
  end
  return result
end

function getRepoPicturePath(extension)
  local result = getRepoPath("pictures")
  if extension then
    result = f"{result}/{extension}"
  end
  return result
end


function getProfileDataPath(extension)
  local result = f"{getMudletHomeDir()}/data"
  if not io.exists(result) then
    lfs.mkdir(result)
  end
  if extension then
    result = f"{result}/{extension}"
  end
  return result
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>colored_print_helper</name>
--##				<packageName></packageName>
--##				<script>-------------------------------------------------
-------------------------------------------------
--         Here are three colored echos        --
--                                             --
-------------------------------------------------

function print_help(filename, verbose)
  for _, line in ipairs(mload_jsonl(filename)) do
    for _, txt in ipairs(line) do
      print(txt)
      if not verbose then
        break
      end
    end
  end
end

local function get_prefix(keyword, reference)
  local result = ""
  if reference then
    result = f("{keyword} ({reference}): ")
  else
    result = f("{keyword}: ")
  end
  return result
end

function wprint(text, reference)
  echo("\n")
  print(text, {get_prefix("WARNUNG", reference), "&lt;255,255,0:0,0,0&gt;"})
  echo("\n")
end

function eprint(text, reference)
  echo("\n")
  print(text, {get_prefix("FEHLER", reference), "&lt;255,155,0:0,0,0&gt;"})
  echo("\n")
end

function iprint(text, reference)
  print(text, {get_prefix("INFO", reference), "&lt;120,170,255:0,0,0&gt;"})
end

local text_farben =
  {
    r = "&lt;235,80,80:0,0,0&gt;",
    g = "&lt;155,255,0:0,0,0&gt;",
    b = "&lt;120,170,255:0,0,0&gt;",
    lb = "&lt;120,170,255:0,0,0&gt;",
    o = "&lt;255,155,55:0,0,0&gt;",
    l = "&lt;155,155,255:0,0,0&gt;",
    y = "&lt;205,205,0:0,0,0&gt;",
    ly = "&lt;255,255,0:0,0,0&gt;",
    c = "&lt;0,255,255:0,0,0&gt;",
    m = "&lt;255,0,255:0,0,0&gt;",
  }
  
local function print_with_breaks(text, pre)
  pre = pre or {"", ""}
  decho(f("{pre[2]}{pre[1]}"))
  local pre_len = len(pre[1])
  local pseudo_pre = ""
  for i = 1, pre_len, 1 do
    pseudo_pre = f("{pseudo_pre} ")
  end
  local line_size = pre_len
  for _, text_part in ipairs(text) do
    woerter = text_part[1]
    farbe = text_farben[text_part[2]] or ""
    for _, word in ipairs(string.split(woerter)) do
      -- check if word contains line break symbols
      local word_tab = string.split(word, "\n")
      if len(word_tab) == 1 then
        if line_size + #word &lt; 78 then
          decho(f("{farbe}{word} "))
          line_size = line_size + #word + 1
        else
          decho(f("\n{pseudo_pre}{farbe}{word} "))
          line_size = pre_len + #word + 1
        end
      else
        if line_size + #word_tab[1] &lt; 78 then
          decho(f("{farbe}{word_tab[1]}"))
        else
          decho(f("\n{pseudo_pre}{farbe}{word_tab[1]}"))
        end
        for i=2,len(word_tab),1 do
          if len(word_tab[i]) == 0 then
            decho(f("\n{pseudo_pre}"))
            line_size = pre_len
          else
            decho(f("\n{pseudo_pre}{farbe}{word_tab[i]} "))
            line_size = pre_len + len(word_tab[1]) + 1
          end
        end
      end
    end
  end
  echo("\n")
end

function print(text, pre)
  if type(pre) == "string" then
    pre = {pre, nil}
  end
  if type(text) == "string" then
    print_with_breaks({{text, nil}}, pre)
  elseif type(text) == "table" then
    new_text = {}
    for _, t in pairs(text) do
      if type(t) == "string" then
        table.insert(new_text, {t, nil})
      elseif type(t) == "table" then
        table.insert(new_text, t)
      end
    end
    print_with_breaks(new_text, pre)
  end
end

function print_table(tab)
  local temp = {}
  for i = 1, #tab do
    for j = 1, #tab[i] do
      if temp[j] then
        table.insert(temp[j], tab[i][j])
      else
        temp[j] = {tab[i][j]}
      end
    end
  end
  for i = 1, #temp do
    for j = 1, #temp[i] do
      decho(temp[i][j])
    end
    echo("\n")
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>formatting_text_helper</name>
--##				<packageName></packageName>
--##				<script>-------------------------------------------------
-------------------------------------------------
--         Put your Lua functions here.        --
--                                             --
-- Note that you can also use external scripts --
-------------------------------------------------

function normalized_text(text) 
  return string.lower(string.gsub(text, "[%c%s]+", ""))
end

function norm_length(strings, orientation, extra)
  local max_len = 0
  if type(orientation) == "number" then
    if (not (orientation == -1)) and (not (orientation == 1)) then
      eprint(
        "Fehler bei der Formatierung: Orientierung muss -1 (rechtsbuendig) oder 1 (linksbuendig) sein."
      )
      return
    end
  else
    orientation = -1
  end
  local len = 0
  for i, v in ipairs(strings) do
    if type(v) == "number" then
      v = tostring(v)
      strings[i] = v
    end
    len = #v
    for m in v:gmatch("&lt;%d+,%d+,%d+:%d+,%d+,%d+&gt;") do
      len = len - #m
    end
    if len &gt; max_len then
      max_len = len
    end
  end
  extra = extra or 0
  local extra_space = ""
  for i = 1,extra,1 do
    extra_space = extra_space.." "
  end
  local temp
  for i = 1, #strings do
    temp = ""
    len = #strings[i]
    for m in strings[i]:gmatch("&lt;%d+,%d+,%d+:%d+,%d+,%d+&gt;") do
      len = len - #m
    end
    for i = 1, max_len - len do
      temp = temp .. " "
    end
    if orientation == -1 then
      strings[i] = extra_space .. strings[i] .. temp .. extra_space
    else
      strings[i] = temp .. extra_space .. strings[i] .. extra_space
    end
  end
  return strings
end

function norm_table(tab, orientations, extras)
  if type(orientations) == "nil" then
    orientation = {}
    for i = 1, len(tab) do
      table.insert(orientation, -1)
    end
  elseif type(orientations) == "number" then
    local orient = orientations
    orientations = {}
    for i = 1, len(tab) do
      table.insert(orientations, orient)
    end
  end
  if type(extras) == "nil" then
    extras = {}
    for i = 1, len(tab) do
      table.insert(extras, 0)
    end
  elseif type(extras) == "number" then
    local extra = extras
    extras = {}
    for i = 1, len(tab) do
      table.insert(extras, extra)
    end
  end
  for i = 1, len(tab) do
    tab[i] = norm_length(tab[i], orientations[i], extras[i])
  end
  return tab
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>io_helper</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>io_load_base</name>
--##				<packageName></packageName>
--##				<script>-------------------------------------------------
-------------------------------------------------
-- generel load/save functions
-------------------------------------------------

function load_csv(path)
  if path == nil then
    eprint("Kein Dateiname zum Laden gegeben.")
    return
  end
  if io.exists(path) then
    local result = {}
    for line in io.lines(path) do
      table.insert(result, string.split(line, ";"))
    end
    return result
  elseif FirstCall:is_first_call(path) then
    save_csv({}, path)
    FirstCall:complete_first_call(path)
    return {}
  else
    local msg = f"Datei {path} zum Laden nicht gefunden"
    printError(msg, true, true)
    return nil
  end
end

function load_tlines(path)
  if path == nil then
    eprint("Kein Dateiname zum Laden gegeben.")
    return
  end
  if io.exists(path) then
    local lines = {}
    for sline in io.lines(path) do
      sline = sline:gsub("\r", "")
      table.insert(lines, sline)
    end
    return lines
  elseif FirstCall:is_first_call(path) then
    save_tlines({}, path)
    FirstCall:complete_first_call(path)
    return {}
  else
    local msg = f"Datei {path} zum Laden nicht gefunden"
    printError(msg, true, true)
    return nil
  end
end

function load_json(path, default)
  default = default or {}
  if path == nil then
    eprint("Kein Dateiname zum Laden gegeben.")
    return
  end
  local file = io.open(path, "r")
  if file then
    local content = file:read("*all")
    file:close()
    return json.decode(content)
  elseif FirstCall:is_first_call(path) then
    save_json(default, path)
    FirstCall:complete_first_call(path)
    return default
  else
    local msg = f"Datei {path} zum Laden nicht gefunden"
    printError(msg, true, true)
    return nil
  end
end

function load_jsonl(path)
  if path == nil then
    eprint("Kein Dateiname zum Laden gegeben.")
    return
  end
  if io.exists(path) then
    local lines = {}
    for sline in io.lines(path) do
      table.insert(lines, json.decode(sline))
    end
    return lines
  elseif FirstCall:is_first_call(path) then
    save_jsonl({}, path)
    FirstCall:complete_first_call(path)
    return {}
  else
    local msg = f"Datei {path} zum Laden nicht gefunden"
    printError(msg, true, true)
    return nil
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>io_save_base</name>
--##				<packageName></packageName>
--##				<script>-------------------------------------------------
-------------------------------------------------
-- generel load/save functions
-------------------------------------------------

function save_csv(lines, path, setting)
  -- delimiter is ; because , are used in descriptions
  if #lines == 0 and io.exists(path) then
    eprint(f"Versuch die Datei {path} leer zu ueberschreiben verhindert!")
    return
  end
  local file = io.open(path, "w")
  local temp
  if setting then
    if type(setting) == 'table' then
      file:write(table.concat(setting, ";"), "\n")
    else
      file:write(setting, "\n")
    end
  end
  for k, v in ipairs(lines) do
    if type(v) == 'table' then
      file:write(table.concat(v, ";") .. "\n")
    else
      file:write(v, "\n")
    end
  end
  file:close()
end

function save_tlines(lines, path)
  if #lines == 0 and io.exists(path) then
    eprint(f"Versuch die Datei {path} leer zu ueberschreiben verhindert!")
    return 
  end
  local file = io.open(path, "w+")
  for _, v in ipairs(lines) do
    file:write(v, "\n")
  end
  file:close()
end


function save_json(tab, path)
  if type(tab) == "table" and len(tab) == 0 and io.exists(path) then
    printError(f"Versuch die Datei {path} leer zu ueberschreiben verhindert!")
    return
  end
  local file = io.open(path, "w")
  if not file then
    display("save?")
    display(path)
  end
  file:write(json.encode(tab))
  file:close()
end

function save_jsonl(tab, path, modifier)
  if len(tab) == 0 and io.exists(path) then
    eprint(f"Versuch die Datei {path} leer zu ueberschreiben verhindert!")
    return
  end
  modifier = modifier or "w"
  local file = io.open(path, modifier)
  for _, line in spairs(tab) do
    file:write(json.encode_oneline(line), "\n")
  end
  file:close()
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>io_profile_load_save</name>
--##				<packageName></packageName>
--##				<script>-------------------------------------------------
-------------------------------------------------
-- profile load/save functions
-------------------------------------------------

function pload_csv(filename)
  -- this function loads a csv file from the profiles folder
  return load_csv(getProfileDataPath(f"{filename}.csv"))
end

function pload_tlines(filename)
  -- this function loads a text file from the profiles folder
  return load_tlines(getProfileDataPath(f"{filename}.txt"))
end

function pload_json(filename, default)
  return load_json(getProfileDataPath(f"{filename}.json"), default)
end

function pload_jsonl(filename)
  return load_jsonl(getProfileDataPath(f"{filename}.jsonl"))
end

function psave_csv(lines, filename, setting)
  -- this function saves a text file from the profiles folder
  --
  return save_csv(lines, getProfileDataPath(f"{filename}.csv"), setting)
end

function psave_tlines(lines, filename)
  -- this function saves a csv file from the profiles folder
  --
  return save_tlines(lines, getProfileDataPath(f"{filename}.txt"))
end

function psave_json(tab, filename)
  return save_json(tab, getProfileDataPath(f"{filename}.json"))
end

function psave_jsonl(tab, filename, modifier)
  return save_jsonl(tab, getProfileDataPath(f"{filename}.jsonl"), modifier)
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>io_module_load_save</name>
--##				<packageName></packageName>
--##				<script>-------------------------------------------------
-------------------------------------------------
-- module load/save functions
-------------------------------------------------

function mload_csv(filename)
  -- this function loads a csv file from the modules folder
  return load_csv(getRepoDataPath(f"{filename}.csv"))
end

function mload_tlines(filename)
  -- this function loads a text file from the modules folder
  return load_tlines(getRepoDataPath(f"{filename}.txt"))
end

function mload_json(filename, default)
  return load_json(getRepoDataPath(f"{filename}.json"), default)
end

function mload_jsonl(filename)
  return load_jsonl(getRepoDataPath(f"{filename}.jsonl"))
end

function msave_csv(lines, filename)
  return save_csv(lines, getRepoDataPath(f"{filename}.csv"))
end

function msave_tlines(lines, filename)
  return save_tlines(lines, getRepoDataPath(f"{filename}.txt"))
end

function msave_json(tab, filename)
  return save_json(tab, getRepoDataPath(f"{filename}.json"))
end

function msave_jsonl(tab, filename)
  return save_jsonl(tab, getRepoDataPath(f"{filename}.jsonl"))
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>io_remove</name>
--##				<packageName></packageName>
--##				<script>-------------------------------------------------
-------------------------------------------------
-- remove file functions
-------------------------------------------------

local function remove(path)
  if io.exists(path) then
    os.remove(path)
    FirstCall:remove_first_call(path)
  end
end

function mremove_csv(filename)
  remove(getRepoDataPath(f"{filename}.csv"))
end

function mremove_tlines(filename)
  remove(getRepoDataPath(f"{filename}.txt"))
end

function mremove_json(filename)
  remove(getRepoDataPath(f"{filename}.json"))
end

function mremove_jsonl(filename)
  remove(getRepoDataPath(f"{filename}.jsonl"))
end

function premove_csv(filename)
  remove(getProfileDataPath(f"{filename}.csv"))
end

function premove_tlines(filename)
  remove(getProfileDataPath(f"{filename}.txt"))
end

function premove_json(filename)
  remove(getProfileDataPath(f"{filename}.json"))
end

function premove_jsonl(filename)
  remove(getProfileDataPath(f"{filename}.jsonl"))
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>io_move</name>
--##				<packageName></packageName>
--##				<script>-------------------------------------------------
-------------------------------------------------
-- move file functions
-------------------------------------------------

local function move(old_file, new_file)
  if io.exists(new_file) then
    return
  end
  if not io.exists(old_file) then
    printError(f"Missing file to move {old_file}")
  end
  os.rename(old_file, new_file)
  FirstCall:remove_first_call(path)
end

function mmove_csv(old_filename, new_filename)
  move(getRepoDataPath(f"{old_filename}.csv"), getRepoDataPath(f"{new_filename}.csv"))
end

function mmove_tlines(old_filename, new_filename)
  move(getRepoDataPath(f"{old_filename}.txt"), getRepoDataPath(f"{new_filename}.txt"))
end

function mmove_json(old_filename, new_filename)
  move(getRepoDataPath(f"{old_filename}.json"), getRepoDataPath(f"{new_filename}.json"))
end

function mmove_jsonl(old_filename, new_filename)
  move(getRepoDataPath(f"{old_filename}.jsonl"), getRepoDataPath(f"{new_filename}.jsonl"))
end

function pmove_csv(old_filename, new_filename)
  move(getProfileDataPath(f"{old_filename}.csv"), getProfileDataPath(f"{new_filename}.csv"))
end

function pmove_tlines(old_filename, new_filename)
  move(getProfileDataPath(f"{old_filename}.txt"), getProfileDataPath(f"{new_filename}.txt"))
end

function pmove_json(old_filename, new_filename)
  move(getProfileDataPath(f"{old_filename}.json"), getProfileDataPath(f"{new_filename}.json"))
end

function pmove_jsonl(old_filename, new_filename)
  move(getProfileDataPath(f"{old_filename}.jsonl"), getProfileDataPath(f"{new_filename}.jsonl"))
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<Script isActive="yes" isFolder="no">
--##			<name>string_extensions</name>
--##			<packageName></packageName>
--##			<script>function break_lines(text, length)
function break_lines(text, length)
  length = length or 59
  local result = {""}
  local index = 1
  for s in text:gmatch("[^%s]+") do
    if len(result[index] .. s) &lt; length then
      if len(result[index]) &gt; 0 then
        result[index] = result[index] .. " " .. s
      else
        result[index] = s
      end
    else
      index = index + 1
      table.insert(result, s)
    end
  end
  return result
end

function substring(text, subtext)
  return string.match(text, subtext)
end

function string.startswith(text, subtext)
  return text:sub(1, #subtext) == subtext
end

function string.endswith(text, subtext)
  return text:sub(-#subtext) == subtext
end

function string.strip(text)
  local start_index = 1
  local end_index = text:len()
  for i=1,text:len(),1 do
    local c=text:sub(i,i)
    if c == " " then
      start_index = i+1
    else
      break
    end
  end
  for i=text:len(),1,-1 do
    local c=text:sub(i,i)
    if c == " " then
      end_index = i-1
    else
      break
    end
  end
  if end_index &lt;= start_index then
    return ""
  else
    return text:sub(start_index, end_index)
  end
end

function string.indent_lines(text, indent)
  local result = {}
  for word in text:gmatch("[^%s]+") do
    local prev = result[len(result)]
    if prev and len(prev) + 1 + len(word) &lt; 78 then
      result[len(result)] = f("{prev} {word}")
    else
      table.insert(result, f("{indent}{word}"))
    end
  end
  return table.concat(result, "\n")
end

function string.rep(txt, size)
  local result = ""
  for _=1,size,1 do
    result = f"{result}{txt}"
  end
  return result
end

function string.fill(text, filler)
  filler = filler or " "
  local left = 76 - len(text)
  local rem = left % 2
  local fill_text = string.rep(filler, ((left-rem) / 2) -1)
  local result = f"{fill_text} {text} {fill_text}"
  if rem &gt; 0 then
    result = f"{result}{filler}"
  end
  return result
end
--##end</script>
--##			<eventHandlerList />
--##		</Script>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>table_extensions</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>table_get_set</name>
--##				<packageName></packageName>
--##				<script>local function deep_set(target, keys, value, idx)
local function deep_set(target, keys, value, idx)
  idx = idx or 1
  local pivot = keys[idx]
  if idx == #keys then
    target[pivot] = value
  else
    if not target[pivot] then
      target[pivot] = {}
    end
    deep_set(target[pivot], keys, value, idx + 1) 
  end
end

function table.set(tab, key, value)
  if type(key) == "string" then
    deep_set(tab, key:split("%."), value)
  elseif type(key) == "table" then
    deep_set(tab, key, value)
  else
    tab[key] = value
  end
end

local function deep_get(source, keys, idx)
  idx = idx or 1
  local pivot = keys[idx]
  if source == nil then
    return nil
  end
  if idx == #keys then
    return source[pivot]
  else
    return deep_get(source[pivot], keys, idx + 1)
  end
end

function table.get(tab, key, default_value)
  local result = nil
  if type(key) == "string" then
    result = deep_get(tab, key:split("%."))
  elseif type(key) == "table" then
    result = deep_get(tab, key)
  else
    result = tab[key]
  end
  if result == nil and default_value ~= nil then
    table.set(tab, key, default_value)
    result = default_value
  end
  return result
end

















--##</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>table_add_append_update</name>
--##				<packageName></packageName>
--##				<script>function table.add(tab, value)
function table.add(tab, value)
  if not table.contains(tab, value) then
    table.insert(tab, value)
  end
end

function table.append_table(tab_a, tab_b)
  for _,item in ipairs(tab_b) do
    table.insert(tab_a, item)
  end
end

function table.update(base_table, updates, keep)
  for key, value in pairs(updates) do
    if type(value) == "table" and type(base_table[key]) == "table" then
      table.update(base_table[key], value, keep)
    elseif (base_table[key] == nil) or not keep then
      base_table[key] = value
    end
  end
  return base_table
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>table_remove</name>
--##				<packageName></packageName>
--##				<script>function table.remove_at(tab, index)
function table.remove_at(tab, index)
  local table_size = len(tab)
  if index &lt; 0 then
    index = table_size + index
    if index &lt; 1 then
      eprint(f("The table has just {table_size} elements, can't remove at position {index}."))
      return false
    end
  end
  if index == 0 or index &gt; len(tab) then
    eprint(f("The table has just {table_size} elements, can't remove at position {index}."))
    return false
  end
  -- shift values
  for i=index+1,len(tab),1 do
    tab[i-1] = tab[i]
  end
  -- remove last element
  table.remove(tab)
  return true
end

function table.remove_value(tab, value)
  local index = table.index_of(tab, value)
  if not index then
    eprint(f("The table has no value '{value}' to remove."))
    return false
  else
    table.remove_at(tab, index)
    return true
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>table_misc</name>
--##				<packageName></packageName>
--##				<script>function table.values(tab)
function table.values(tab)
  local result = {}
  for _, value in pairs(tab) do
    table.insert(result, value)
  end
  return result
end

function table.fold(tab, field_name)
  -- transform a table such that the keys 
  -- part of the values.
  -- {st={title="Sandtiger"}} with 
  -- field_name == "name" will return
  -- { {name="st", title="Sandtiger"} }

  local result = {}
  for id, props in pairs(tab) do
    local data = {}
    data[field_name] = id
    for pkey, pvalue in pairs(props) do
      data[pkey] = pvalue
    end
    table.insert(result, data)
  end
  return result
end

function table.unfold(tab, field_name)
  -- inverse to table.fold we move a value
  -- out of the data as a key of the result
  
  local result = {}
  for _, data in spairs(tab) do
    local id = nil
    local props = {}
    for pkey, pvalue in pairs(data) do
      if pkey == field_name then
        id=pvalue
      else
        props[pkey] = pvalue
      end
    end
    result[id] = props
  end
  return result
end

function table.apply(tab, func)
  local result = {}
  for _, v in pairs(tab) do
    table.insert(result, func(v))
  end
  return result
end

function table.subtable(tab, start_index, end_index)
  local result = {}
  for i=start_index,end_index,1 do
    table.insert(result, tab[i])
  end 
  return result
end

function table.indent_lines(tab, indent)
  local new_line = f("\n{indent}")
  local result = f("{indent}{table.concat(tab, new_line)}") 
  return result
end

function table.indent_lines_with_breaks(tab, indent)
  local result = {}
  for _,line in ipairs(tab) do
    table.insert(result, string.indent_lines(line, indent))
  end
  return table.concat(result, "\n")
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>MundronClassMethods</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>MCM_init</name>
--##				<packageName></packageName>
--##				<script>------------------------------------
------------------------------------
---  Meta-table for class objects.
------------------------------------

MundronClassMethods = MundronClassMethods or {
  _name = "MundronClassMethods",
  _module = "Mundron_Core",
  _meta_name = "MundronClassMethods_meta",
  _version = "1.0.0",
  pload = pload_json,
  mload = mload_json,
  psave = psave_json, 
  msave = msave_json,
  premove = premove_json,
  mremove = mremove_json,
  pmove = pmove_json,
  mmove = mmove_json,
}

MCM = MundronClassMethods

local function init_data(object)
  return function(event_name, module_name)
    if event_name == "sysInstall" and module_name ~= object._module then
      return
    end
    object:log(f"Triggered load function by event {event_name} from {module_name}")
    if event_name == object:load_event_name() then
      object:log("Only game files will be loaded")
      object:generic_load_data("game")
    else
      object:log("Load profile, game and config files")
      object:load_data() -- load both: game and profile!
    end
    if object.post_load_data then
      object:post_load_data()
    end
    if event_name == "sysInstall" then
      object.premove(object:name("log"))
    end
  end
end

local function init_help(object)
  return function(event_name, module_name)
    if module_name ~= object._module then
      return
    end
    object:log(f"Triggered build of help by event {event_name} from {module_name}")
    object:build_help()
  end
end

function MundronClassMethods:new(t)
  -- assert test fields
  assert(type(t) == "table", "MundronClassMethods: Incoming object is no table")
  for _, field in ipairs({"_name", "_version", "_module"}) do
    assert(t[field], f"MundronClassMethods: Missing required field: '{field}'")
  end
  
  -- create object and add inferrences
  local object = setmetatable(t, self)
  self.__index = self
  -- display(object)
  for _, field in pairs({"config", "meta"}) do
    object[f"_{field}_name"] = object:name(field)
  end
  for _, field in pairs({"data", "log_buffer", "help", "state"}) do
    object[field] = table.get(object, field, {})
  end
  
  if len(table.get(object, "help")) &gt; 0 then
    -- if there are any help entries, initialize or update help aliases
    -- once the module is installed
    registerAnonymousEventHandler("sysInstall", init_help(object))
  end
  if len(table.get(object, "files")) &gt; 0 or object.config then
    -- if any files are to load for data or config, register function for
    -- a) initial load data/config once the module is installed
    registerAnonymousEventHandler("sysInstall", init_data(object))
  end
  if len(table.get(object, "files.game")) &gt; 0 then
    -- if there are game files, registers function to reload game data
    -- whenever any profile saves game data of the same object
    registerAnonymousEventHandler(object:load_event_name(), init_data(object))
  end
  
  -- inherit callability
  object.__call = self.__call
  
  return object
end

function MundronClassMethods:extend(child)
  child = child or {}
  child.__index = child
  child.__call = self.__call
  return setmetatable(child, self)   -- inherits methods + metamethods (e.g., __call) from base
end

--##</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>MCM_names</name>
--##				<packageName></packageName>
--##				<script>function MundronClassMethods:name(extra)
function MundronClassMethods:name(extra)
  local result = self._name
  if extra then
    extra = extra:gsub("%.", "_")
    result = f"{result}_{extra}" 
  end
  return result
end

function MundronClassMethods:shortname(extra)
  local result = self._shortname or self._name
  if extra then
    extra = extra:gsub("%.", "_")
    result = f"{result}_{extra}"
  end
  return result
end

function MundronClassMethods:filename(extra)
  extra = extra:gsub("%.", "_")
  local result = f"{self:shortname()}/{extra}"
  return result
end

function MundronClassMethods:load_event_name()
  local event_name = f"load_game_data_for_{self:name()}_from_{self:name('module')}"
  return event_name
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>MCM_base_migration</name>
--##				<packageName></packageName>
--##				<script>function MundronClassMethods:base_migrate_(key, base_version)
function MundronClassMethods:base_migrate_(key, base_version)
  self:log(f"Base migration for {key} because MundronClassMethods updated from version '{version}'")
  if key == "profile" then
    self:base_migrate_profile(version)
  else
    self:base_migrate_game(version)
  end
  self:log("Migration completed")
end

function MundronClassMethods:base_migrate_profile(version)

end

function MundronClassMethods:base_migrate_game(version)

end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>MCM_migration</name>
--##				<packageName></packageName>
--##				<script>function MundronClassMethods:check_for_migrations(key)
function MundronClassMethods:check_for_migrations(key)
  local saved_versions = self:fetch_from_(key, self:filename("versions"), {})
  local msg = f"Got saved versions '{json.encode_oneline(saved_version)}' for {key}"
  self:log(msg)
  local fun_name = f"migrate_{key}"
  for _, mtab in ipairs(self:inheritance()) do 
    -- check version and call accordingly migration
    local saved_mversion = saved_versions[mtab._name]
    if not table.get(mtab, f"files.{key}") then
      saved_versions[mtab._name] = mtab._version
    elseif saved_versions[mtab._name] &lt; mtab._version then
      local msg = f"Call migration of {mtab._name} from version '{saved_mversion}' to '{mtab._version}'"
      self:log(msg)
      local migrate_function = rawget(mtab, fun_name)
      if type(migrate_function) ~= "function" then
        local err = f"Missing function {fun_name} for module {mtab._name}"
        self:error(err, false)
        break
      end
      local result_version = migrate_function(self, key, saved_mversion)
      saved_versions[mtab._name] = result_version
      if result_version ~= saved_mversion then
        local err = f"Migration of {mtab._name} ended in version {result_version} instead of expected {saved_mversion}"
        self:error(err, false)
        break
      end
    end
  end
  self:store_into_(key, self:filename("versions"), saved_versions)
end

--[[
function MundronClassMethods:migrate_(key, version)
  self:log(f"Start MundronClassMethods:migrate_({key}, '{version}')")
  local result
  if key == "profile" then
    result = self:migrate_profile(version)
  else
    result = self:migrate_game(version)
  end
  self:log(f"End MundronClassMethods:migrate({key}, '{version}') with result '{result}'")
  return result
end]]--

-- dummy functions to raise NotImplementedError if required but forgotten!
function MundronClassMethods:migrate_profile()
  if self._name ~= MundronClassMethods._name then
    local err = f"Migration of profile files for {self._name} not implemented!" 
    self:error(err)
  end
end

function MundronClassMethods:migrate_game()
  if self._name ~= MundronClassMethods._name then
    local err = f"Migration of game files for {self._name} not implemented!" 
    self:error(err)
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>MCM_generic_load_data</name>
--##				<packageName></packageName>
--##				<script>function MundronClassMethods:fetch_from_(key, filename, default)
function MundronClassMethods:fetch_from_(key, filename, default)
  self:log(f"Fetch {key} data from {filename}")
  local result
  if key == "profile" then
    result = self.pload(filename, default)
  else
    result = self.mload(filename, default)
  end
  local msg = f"Got result {type(result)} - {len(result)}"
  self:info(msg)
  return result
end

function MundronClassMethods:generic_load_data(key)
  if self.files[key] == nil then
    return
  end

  -- do migrations if needed
  self:check_for_migrations(key)
  
  -- load data
  data_tab = table.get(self, "data", {})
  for field, default in pairs(self.files[key] or {}) do
    saved_data = self:fetch_from_(key, self:name(field), default)
    local line = json.encode_oneline(saved_data)
    if field == "COMPACT" then
      table.update(data_tab, saved_data)
    else
      table.set(data_tab, field, saved_data)    
    end
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>MCM_generic_save_data</name>
--##				<packageName></packageName>
--##				<script>function MundronClassMethods:store_into_(key, data, filename)
function MundronClassMethods:store_into_(key, data, filename)
  if type(data) == "table" and len(data) == 0 then
    return
  end
  if key == "profile" then
    self.psave(data, filename)
  else
    self.msave(data, filename)
  end
end

function MundronClassMethods:generic_save_data(key)
  for field, default in pairs(self.files[key] or {}) do
    if field == "COMPACT" then
      local data_to_save = {}
      for subfield,subdefault in pairs(default) do
        data_to_save[subfield] = table.get(self, {"data", subfield}, subdefault)
      end
      self:store_into_(key, data_to_save, self:name(field))
    else
      self:store_into_(key, table.get(self.data, field, default), self:name(field))
    end
  end
  if key == "game" then
    raiseGlobalEvent(self:load_event_name())
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>MCM_specific_load_save_data</name>
--##				<packageName></packageName>
--##				<script>function MundronClassMethods:load_data()
function MundronClassMethods:load_data()
  if not self.files then
    self:log("No files to load at all")
    return
  end
  for _, target in pairs({"game", "profile"}) do
    if self.files[target] then
      self:generic_load_data(target)
    end  
  end
end

function MundronClassMethods:load_profile()
  self:generic_load_data("profile")
end

function MundronClassMethods:load_game()
  self:generic_load_data("game")
end

function MundronClassMethods:save_data()
  if not self.files then
    self:log("No files to save at all")
    return
  end
  for _, target in pairs({"game", "profile"}) do
    if self.files[target] then
      self:generic_save_data(target)
    end  
  end
end

function MundronClassMethods:save_profile()
  self:generic_save_data("profile")
end

function MundronClassMethods:save_game()
  self:generic_save_data("game")
end
  

--##</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>MSC_log_and_info</name>
--##				<packageName></packageName>
--##				<script>


function MundronClassMethods:log(text, level)
  level = level or "info"
  table.insert(self.log_buffer, {os.date("%Y-%m-%dT%H:%M:%S"), level, text})
end

function MundronClassMethods:show_log()
  if len(self.log_buffer) == 0 then
    self:info({"~ Nothing logged yet! ~", "y"})
  end
  for _, line in pairs(self.log_buffer) do
    print({line[1], {string.upper(line[2]), "y"}, line[3]})
  end
end

function MundronClassMethods:info(text)
  iprint(text, self._shortname or self._name)
  self:log(text, "info")
end

function MundronClassMethods:warn(text)
  wprint(text, self._shortname or self._name)
  self:log(text, "warn")
end

function MundronClassMethods:error(text, haltExecution)
  eprint(text, self._shortname or self._name)
  self:log(text, "error")
  -- halt if haltExecution is nil otherwise use haltExecution
  printError(text, true, haltExection == nil or haltExecution)
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>MCM_misc</name>
--##				<packageName></packageName>
--##				<script>function MundronClassMethods:rabbit()
function MundronClassMethods:rabbit()
  self:info("Because my girlfriend likes rabbits as in RabbitMQ or in redwine juice.")
end
------------------------------------------------------
local function is_meta(key)
  return key:sub(1,1) == "_" and key:sub(1,2) ~= "__"
end

local function is_simple_value(value)
  local t = type(value)
  return t == "string" or t == "number" or t == "boolean"
end

------------------------------------------------------
function MundronClassMethods:__call(parent)
  if not parent then
    mtable = self
  else
    print(string.rep("=", 50))
    print("Metatable hierachy:")
    print(f"{parent}) {self._name}")
    mtable = getmetatable(self)
    if not mtable then
      self:error("No metatable found")
    end
    parent = parent - 1
    while parent &gt; 0 do
      print(f"{parent}) {mtable._name}")
      mtable = getmetatable(mtable)
      if not mtable then
        self:error("Overstepped metatable depth")
      end
      parent = parent - 1
    end
  end
  
  print(string.rep("=", 50))
  print(f"Consider functions of table/metatable {mtable._name}")
  local functions = mtable:functions()
  for _, fn in pairs(functions) do
    print({{fn, "y"}})
  end
    
  print(string.rep("=", 50))
  local meta, level = getmetatable(mtable), 1
  if not meta then
    print("No higher metatables")
  else
    print("Higher metatables:")
    while meta do
      print(f"{level}) {meta._name}")
      meta, level = getmetatable(meta), level + 1
    end
  end
end

function MundronClassMethods:meta()
  local result = {}
  for k,v in pairs(self) do
    if is_meta(k) and type(v) ~= "function" then
      result[k] = v
    end
  end
  return result
end

function MundronClassMethods:inheritance()
  local result, mtable = {}, self
  while mtable do
    table.insert(result, 1, mtable)
    mtable = getmetatable(mtable)
  end
  return result
end

function MundronClassMethods:keys(parent)
  local base = self
  if parent ~= nil then
    base = table.get(self, parent)
  end
  if len(base) == 0 then
    self:info(f"Got empty list for key {parent}")
  end
  for key, value in pairs(base) do
    local var_type = type(value)
    if not (is_meta(key) or var_type == "function") then
      if var_type == "table" then
        print(f"{key}: table -&gt; length {len(value)}")
      elseif is_simple_value(value) then
        print(f"{key}: type {var_type} -&gt; {value}")
      end  
    end
  end
end

function MundronClassMethods:functions()
  local result = {}
  for key, value in pairs(self) do
    if key:sub(1,2) ~= "__" and type(value) == "function" then
      table.insert(result, key)
    end
  end
  table.sort(result)
  return result
end


--##</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>MCM_help</name>
--##				<packageName></packageName>
--##				<script>function MundronClassMethods:helptrigger(extra)
function MundronClassMethods:helptrigger(extra)
  local result = f"?{self:shortname()}{extra or ''}"
end

function MundronClassMethods:build_help()
  self._help_group = self:shortname("help")
  if not exists(self._help_group, "alias") then
    permGroup(self._help_group, "alias", self._module)
  end
  local all_ids = findItems(self:helptrigger(), "alias", self._help_group)
  -- create potential aliases
  local potentials = {}
  for key, desc in pairs(self.help) do
   
  end
  -- check which already exists and remove from all_ids
  -- create missing aliases
  -- kill old aliases
end

function MundronClassMethods:display_help(key)
  print(table.get(self.help, key) or "no help found")
end

function MundronClassMethods:add_help(key, description)
  table.set(self.help, {key, description})
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>MCM_global_help</name>
--##				<packageName></packageName>
--##				<script>function MundronClassMethods:show_global_help()
function MundronClassMethods:show_global_help()
  print(string.rep("=", 50))
  print("High-Level Hilfen:")
  for _, mname in ipairs(self.help) do
    print(f"   {mname}")
  end
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<ScriptGroup isActive="yes" isFolder="yes">
--##			<name>FirstCall</name>
--##			<packageName></packageName>
--##			<script></script>
--##			<eventHandlerList />
--##			<Script isActive="yes" isFolder="no">
--##				<name>FirstCall_init</name>
--##				<packageName></packageName>
--##				<script>

FirstCall = FirstCall or MundronClassMethods:new{
  _name = "FirstCall",
  _module = "Mundron_Core",
  _version = "1.0.0",
  data = {},
  files = {game={created={}}}
}

local function get_path(filename)
  -- IMPORTANT: Don't use getRepoDataPath with argument to avoid infinite stack!
  -- with an argument, it falls is_first_call where this function is called
  -- from.
  local result = f"{getRepoDataPath()}/{filename}.json"
  return result
end

function FirstCall.mload(filename, default)
  local file = io.open(get_path(filename), "r")
  if file == nil then
    FirstCall.msave(default, filename)
    return {}
  end
  local content = file:read("*all")
  file:close()
  return json.decode(content)
end

function FirstCall.msave(tab, filename)
  local file = io.open(get_path(filename), "w")
  file:write(json.encode(tab))
  file:close()
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>FirstCall_functions</name>
--##				<packageName></packageName>
--##				<script>function FirstCall:is_first_call(name)
function FirstCall:is_first_call(name)
  return not self.data.created[name]
end

function FirstCall:complete_first_call(name)
  self.data.created[name] = true
  self:save_data()
end

function FirstCall:remove_first_call(name)
  if not self.data.created then
    self:error("FirstCall calles to seen")
  end
  self.data.created[name] = nil
  self:save_data()
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##			<Script isActive="yes" isFolder="no">
--##				<name>FirstCall_migrations</name>
--##				<packageName></packageName>
--##				<script>function FirstCall:migrate_game(saved_version)
function FirstCall:migrate_game(saved_version)
  display("migration 1")
  if saved_version &lt; "1.0.0" then
    display("migration 2")
    mmove_json("first_call_map", self:name("created"))
    display("migration 3")
  end
  display("migration 4")
end
--##end</script>
--##				<eventHandlerList />
--##			</Script>
--##		</ScriptGroup>
--##		<Script isActive="yes" isFolder="no">
--##			<name>initGMCP</name>
--##			<packageName></packageName>
--##			<script>-------------------------------------------------
-------------------------------------------------
--   Sagt gmcp, dass er alle Daten senden soll --
-------------------------------------------------

function initGMCP()
  if not gmpc_is_initialized then
    sendGMCP([[Core.Supports.Set [ "MG.char 1", "MG.room 1", "comm.channel 1" ] ]])
    if deleteOldProfiles then
      deleteOldProfiles(7)
    end
    gmcp_is_initialized = true
  end
end

function gmcp_available(path)
  return table.get(gcmp or {}, path) ~= nil
end
--##end</script>
--##			<eventHandlerList>
--##				<string>gmcp.Char</string>
--##			</eventHandlerList>
--##		</Script>
--##		<Script isActive="yes" isFolder="no">
--##			<name>color_communication</name>
--##			<packageName></packageName>
--##			<script>farben = {
farben = {
  vg = {
    komm = "cyan", 
    ebenen = "red", 
    info = "green", 
    alarm = "white", 
    script = "dark_green"
  },
  bg = {
    komm = "black", 
    ebenen = "black", 
    info = "black", 
    alarm = "red", 
    script = "black"
  },
}
function set_text_color(fg_type, bg_type)
  local fg_color = farben.vg[fg_type] or fg_type
  local bg_color = farben.bg[bg_type] or bg_type or farben.bg[fg_type] or fg_color
  fg(fg_color)
  bg(bg_color)
end

function color_communication()
  set_text_color("ebenen")
  echo(gmcp.comm.channel.msg)
  resetFormat()
end

function set_line_color(fg_type, bg_type)
  select_line_color(fg_type, bg_type)
  resetFormat()
end

function select_line_color(fg_type, bg_type)
  selectCurrentLine()
  set_text_color(fg_type, bg_type)
end
--##end</script>
--##			<eventHandlerList>
--##				<string>gmcp.comm.channel</string>
--##			</eventHandlerList>
--##		</Script>
