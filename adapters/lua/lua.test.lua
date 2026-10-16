local root = assert(arg[1])
local glyphbook = dofile(root .. '/adapters/lua/lua.lua')

local function decode_fixture(contents)
  assert(contents:find('"schemaVersion"'))
  return {
    icons = {
      { applications = { 'terminal' }, glyph = '󰊠' },
      { editorFiletypes = { 'lua' }, glyph = '', highlight = 'MiniIconsAzure', color = '#0EA5E9' },
      { files = { 'example.lua' }, glyph = 'F' },
      { extensions = { 'tar.gz' }, glyph = 'W' },
      { extensions = { 'gz', 'lua' }, glyph = 'E' },
      { defaults = { 'file' }, glyph = 'D' },
      { domains = { 'github.com', '*.github.com' }, glyph = '', color = '#8B949E' },
      { domains = { '*.docs.github.com' }, glyph = 'D', color = '#123456' },
      { domains = { '*' }, glyph = '󰖟', color = '#8B949E' },
    },
  }
end

local catalog = glyphbook.load(root .. '/catalog/icons.json', decode_fixture)
assert(glyphbook.get_application(catalog, 'terminal').glyph == '󰊠')
assert(glyphbook.get(catalog, 'editor_filetype', 'LUA').glyph == '')
assert(glyphbook.get_website(catalog, 'GitHub.com').domains[1] == 'github.com')
assert(glyphbook.get_website(catalog, 'https://github.com/path?query#fragment').domains[1] == 'github.com')
assert(glyphbook.get_website(catalog, 'docs.github.com').domains[1] == 'github.com')
assert(glyphbook.get_website(catalog, 'api.docs.github.com').glyph == 'D')
local fallback, is_fallback = glyphbook.get_website(catalog, 'unknown.example')
assert(is_fallback and fallback.glyph == '󰖟')
local websites = glyphbook.list(catalog, 'website')
assert(websites[1] == '*.docs.github.com' and websites[2] == '*.github.com' and websites[3] == 'github.com')
assert(glyphbook.list(catalog, 'editor_filetype')[1] == 'lua')
assert(glyphbook.get_file(catalog, 'example.lua', 'lua').glyph == 'F')
assert(glyphbook.get_file(catalog, 'archive.tar.gz', 'lua').glyph == 'W')
assert(glyphbook.get_file(catalog, 'unknown.lua', 'lua').glyph == 'E')
assert(glyphbook.get_file(catalog, '.env.local', 'lua').glyph == '')
assert(glyphbook.get_file(catalog, 'unknown', 'lua').glyph == '')
assert(glyphbook.get_file(catalog, 'unknown').glyph == 'D')

local limit_ms = 10
local samples = 100
local catalog_size = 11000
local performance_catalog = { icons = {} }

for index = 1, catalog_size do
  table.insert(performance_catalog.icons, {
    extensions = { 'extension-' .. index },
    files = { 'file-' .. index },
    editorFiletypes = { 'filetype-' .. index },
    domains = { 'domain-' .. index .. '.example.com' },
    glyph = tostring(index),
  })
end

table.insert(performance_catalog.icons, { domains = { '*' }, glyph = 'fallback' })
table.insert(performance_catalog.icons, { defaults = { 'file' }, glyph = 'default' })

local function percentile(timings, percentile_rank)
  table.sort(timings)
  return timings[math.ceil(#timings * percentile_rank)]
end

local function assert_latency(name, lookup)
  for _ = 1, samples do lookup() end

  local timings = {}
  for _ = 1, samples do
    local start = os.clock()
    assert(lookup())
    table.insert(timings, (os.clock() - start) * 1000)
  end

  local p95 = percentile(timings, 0.95)
  assert(p95 < limit_ms, string.format('%s p95 %.3f ms exceeds %d ms', name, p95, limit_ms))
end

assert_latency('generic lookup', function()
  return glyphbook.get(performance_catalog, 'extension', 'extension-' .. catalog_size)
end)

assert_latency('website lookup', function()
  return glyphbook.get_website(performance_catalog, 'domain-' .. catalog_size .. '.example.com')
end)

assert_latency('file lookup', function()
  return glyphbook.get_file(performance_catalog, 'file-' .. catalog_size, 'filetype-' .. catalog_size)
end)
