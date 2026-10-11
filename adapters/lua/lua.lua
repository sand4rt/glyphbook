local M = {}

function M.load(path, decode)
  local file, err = io.open(path, 'rb')
  if not file then error(err) end

  local contents = file:read('*a')
  file:close()
  return decode(contents)
end

function M.get_application(catalog, name)
  for _, icon in ipairs(catalog.icons) do
    for _, application in ipairs(icon.applications or {}) do
      if application == name then return icon end
    end
  end
end

local function contains(values, target)
  for _, value in ipairs(values) do
    if value == target then return true end
  end
  return false
end

local fields = {
  default = 'defaults', directory = 'directories', extension = 'extensions',
  file = 'files', editor_filetype = 'editorFiletypes', lsp = 'lsp', os = 'operatingSystems',
}

function M.get(catalog, category, name)
  if category == 'application' then return M.get_application(catalog, name) end
  if category == 'website' then return M.get_website(catalog, name) end
  local field = fields[category]
  if field == nil then error('unknown icon category: ' .. tostring(category)) end
  if category ~= 'file' and category ~= 'directory' then name = name:lower() end
  for _, icon in ipairs(catalog.icons) do
    for _, match in ipairs(icon[field] or {}) do
      if match == name then return icon end
    end
  end
end

function M.list(catalog, category)
  local result = {}
  local seen = {}
  local function add(name)
    if not seen[name] then
      seen[name] = true
      table.insert(result, name)
    end
  end
  if category == 'application' then
    for _, icon in ipairs(catalog.icons) do
      for _, name in ipairs(icon.applications or {}) do add(name) end
    end
  elseif category == 'website' then
    for _, icon in ipairs(catalog.icons) do
      for _, name in ipairs(icon.domains or {}) do
        if name ~= '*' then add(name) end
      end
    end
  elseif fields[category] ~= nil then
    for _, icon in ipairs(catalog.icons) do
      for _, name in ipairs(icon[fields[category]] or {}) do add(name) end
    end
  else
    error('unknown icon category: ' .. tostring(category))
  end
  table.sort(result)
  return result
end

function M.get_website(catalog, host)
  host = host:lower()
  local wildcard, wildcard_length, fallback
  for _, website in ipairs(catalog.icons) do
    for _, domain in ipairs(website.domains or {}) do
      if domain == host then return website, false end
      if domain == '*' then
        fallback = website
      elseif domain:sub(1, 2) == '*.' then
        local suffix = domain:sub(3)
        if host:sub(-#suffix - 1) == '.' .. suffix and #suffix > (wildcard_length or 0) then
          wildcard, wildcard_length = website, #suffix
        end
      end
    end
  end
  if wildcard then return wildcard, false end
  if fallback then return fallback, true end
  return nil, false
end

function M.get_file(catalog, path, filetype)
  local name = path:match('[^/\\]+$') or path
  local exact = M.get(catalog, 'file', name)
  if exact ~= nil then return exact, false end

  local suffix = name:match('^[^.]*%.(.+)$')
  while suffix do
    local icon = M.get(catalog, 'extension', suffix)
    if icon ~= nil then return icon, false end
    suffix = suffix:match('^[^.]*%.(.*)$')
    if suffix == '' then suffix = nil end
  end

  if filetype ~= nil then
    local icon = M.get(catalog, 'editor_filetype', filetype)
    if icon ~= nil then return icon, false end
  end

  return M.get(catalog, 'default', 'file'), true
end

return M
