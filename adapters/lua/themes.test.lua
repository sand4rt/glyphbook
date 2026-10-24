local root = assert(vim.env.GLYPHBOOK_ROOT)
local glyphbook = dofile(root .. '/adapters/lua/lua.lua')
local icons = glyphbook.open({
  catalog = root .. '/catalog/icons.json',
  themeResolver = root .. '/adapters/python/themes.py',
  theme = 'github-dark-dimmed',
  decode = vim.json.decode,
})
assert(icons.get_website('https://github.com/').color == '#cdd9e5')
assert(icons.get('website', 'github.com').color == '#cdd9e5')
assert(icons.map('website')['github.com'].color == '#cdd9e5')
assert(icons.map('website')['*.github.com'] == nil)
assert(icons.get_file('example.nix').color ~= nil)
assert(icons.map('editor-filetype').nix.color ~= nil)
print('Lua theme checks passed')
