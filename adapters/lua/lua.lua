local M = {}

local indexes = setmetatable({}, { __mode = 'k' })

function M.load(path, decode)
  local file, err = io.open(path, 'rb')
  if not file then error(err) end

  local contents = file:read('*a')
  file:close()
  return decode(contents)
end

local function shell_quote(value)
  return "'" .. value:gsub("'", "'\\''") .. "'"
end

function M.open(options)
  assert(options and options.resolver and options.index and options.records and options.decode,
    'resolver, index, records, and decode are required')

  local function run(arguments)
    local command = {
      shell_quote(options.resolver), '--index', shell_quote(options.index),
      '--records', shell_quote(options.records),
    }
    for _, argument in ipairs(arguments) do table.insert(command, shell_quote(argument)) end
    local process = assert(io.popen(table.concat(command, ' '), 'r'))
    local output = process:read('*a')
    local success = process:close()
    if not success or output == '' then return nil end
    return options.decode(output)
  end

  return {
    get = function(category, name)
      if category == 'website' then return run({ 'website', name }) end
      return run({ 'get', category, name })
    end,
    get_application = function(name) return run({ 'get', 'application', name }) end,
    get_website = function(host) return run({ 'website', host }) end,
    get_file = function(path, filetype)
      local arguments = { 'file', path }
      if filetype ~= nil then table.insert(arguments, filetype) end
      return run(arguments)
    end,
    list = function(category)
      local command = {
        shell_quote(options.resolver), '--index', shell_quote(options.index),
        '--records', shell_quote(options.records), 'list', shell_quote(category),
      }
      local process = assert(io.popen(table.concat(command, ' '), 'r'))
      local names = {}
      for name in process:lines() do table.insert(names, name) end
      if not process:close() then return nil end
      return names
    end,
    map = function(category)
      local command = {
        shell_quote(options.resolver), '--index', shell_quote(options.index),
        '--records', shell_quote(options.records), 'map', shell_quote(category),
      }
      local process = assert(io.popen(table.concat(command, ' '), 'r'))
      local result = {}
      for line in process:lines() do
        local name, record = line:match('^([^\t]+)\t(.+)$')
        result[name] = options.decode(record)
      end
      if not process:close() then return nil end
      return result
    end,
  }
end

local fields = {
  default = 'defaults', directory = 'directories', extension = 'extensions',
  file = 'files', editor_filetype = 'editorFiletypes', lsp = 'lsp', os = 'operatingSystems',
}

local function normalize(category, name)
  if category ~= 'file' and category ~= 'directory' and category ~= 'application' then
    return name:lower()
  end
  return name
end

local function build_index(catalog)
  local index = { maps = {}, lists = {}, domains = {}, wildcards = {} }
  index.maps.application = {}
  for category in pairs(fields) do index.maps[category] = {} end

  for _, icon in ipairs(catalog.icons) do
    for _, application in ipairs(icon.applications or {}) do
      if index.maps.application[application] == nil then index.maps.application[application] = icon end
    end
    for category, field in pairs(fields) do
      for _, name in ipairs(icon[field] or {}) do
        name = normalize(category, name)
        if index.maps[category][name] == nil then index.maps[category][name] = icon end
      end
    end
    for _, domain in ipairs(icon.domains or {}) do
      if domain == '*' then
        index.fallback = icon
      elseif domain:sub(1, 2) == '*.' then
        local suffix = domain:sub(3)
        if index.wildcards[suffix] == nil then index.wildcards[suffix] = icon end
      elseif index.domains[domain] == nil then
        index.domains[domain] = icon
      end
    end
  end

  for category, map in pairs(index.maps) do
    local names = {}
    for name in pairs(map) do table.insert(names, name) end
    table.sort(names)
    index.lists[category] = names
  end
  local websites = {}
  for domain in pairs(index.domains) do table.insert(websites, domain) end
  for suffix in pairs(index.wildcards) do table.insert(websites, '*.' .. suffix) end
  table.sort(websites)
  index.lists.website = websites
  return index
end

local function get_index(catalog)
  local index = indexes[catalog]
  if index == nil then
    index = build_index(catalog)
    indexes[catalog] = index
  end
  return index
end

function M.get_application(catalog, name)
  return get_index(catalog).maps.application[name]
end

function M.get(catalog, category, name)
  if category == 'application' then return M.get_application(catalog, name) end
  if category == 'website' then return M.get_website(catalog, name) end
  local field = fields[category]
  if field == nil then error('unknown icon category: ' .. tostring(category)) end
  return get_index(catalog).maps[category][normalize(category, name)]
end

function M.list(catalog, category)
  if category ~= 'application' and category ~= 'website' and fields[category] == nil then
    error('unknown icon category: ' .. tostring(category))
  end
  local result = {}
  for index, name in ipairs(get_index(catalog).lists[category]) do result[index] = name end
  return result
end

function M.map(catalog, category)
  if category ~= 'application' and fields[category] == nil then
    error('unknown icon category: ' .. tostring(category))
  end
  local result = {}
  for name, icon in pairs(get_index(catalog).maps[category]) do result[name] = icon end
  return result
end

function M.get_website(catalog, host)
  host = host:lower()
  host = host:gsub('^%a[%w+.-]*://', ''):gsub('[/?#].*$', ''):gsub('^.-@', ''):gsub(':%d+$', '')
  local index = get_index(catalog)
  local exact = index.domains[host]
  if exact ~= nil then return exact, false end
  local suffix = host:match('^[^.]+%.(.+)$')
  while suffix do
    local wildcard = index.wildcards[suffix]
    if wildcard ~= nil then return wildcard, false end
    suffix = suffix:match('^[^.]+%.(.+)$')
  end
  if index.fallback then return index.fallback, true end
  return nil, false
end

function M.get_file(catalog, path, filetype)
  local name = path:match('[^/\\]+$') or path
  local index = get_index(catalog)
  local exact = index.maps.file[name]
  if exact ~= nil then return exact, false end

  local suffix = name:match('^[^.]*%.(.+)$')
  while suffix do
    local icon = index.maps.extension[suffix:lower()]
    if icon ~= nil then return icon, false end
    suffix = suffix:match('^[^.]*%.(.*)$')
    if suffix == '' then suffix = nil end
  end

  if filetype ~= nil then
    local icon = index.maps.editor_filetype[filetype:lower()]
    if icon ~= nil then return icon, false end
  end

  return index.maps.default.file, true
end

return M
