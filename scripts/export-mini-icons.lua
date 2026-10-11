local source = assert(vim.env.GLYPHBOOK_MINI_NVIM, 'GLYPHBOOK_MINI_NVIM is required')
local output = assert(vim.env.GLYPHBOOK_MINI_OUTPUT, 'GLYPHBOOK_MINI_OUTPUT is required')

vim.opt.runtimepath:prepend(source)
require('mini.icons').setup()

local categories = { 'default', 'directory', 'extension', 'file', 'filetype', 'lsp', 'os' }
local colors = {
  MiniIconsAzure = '#0EA5E9',
  MiniIconsBlue = '#3B82F6',
  MiniIconsCyan = '#06B6D4',
  MiniIconsGreen = '#22C55E',
  MiniIconsGrey = '#8B949E',
  MiniIconsOrange = '#F97316',
  MiniIconsPurple = '#A855F7',
  MiniIconsRed = '#EF4444',
  MiniIconsYellow = '#EAB308',
}

local fields = {
  default = 'defaults',
  directory = 'directories',
  extension = 'extensions',
  file = 'files',
  filetype = 'editorFiletypes',
  lsp = 'lsp',
  os = 'operatingSystems',
}
local result = {}
for _, category in ipairs(categories) do
  for _, name in ipairs(MiniIcons.list(category)) do
    local glyph, highlight = MiniIcons.get(category, name)
    table.insert(result, {
      glyph = glyph,
      highlight = highlight,
      color = colors[highlight] or colors.MiniIconsGrey,
      source = 'mini.icons',
      [fields[category]] = { name },
    })
  end
end

vim.fn.writefile({ vim.json.encode(result) }, output)
vim.cmd.quit()
