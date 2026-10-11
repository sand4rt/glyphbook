local expected = vim.env.GLYPHBOOK_EXPECTED_GLYPH or 'G'
local expected_file = vim.env.GLYPHBOOK_EXPECTED_FILE_GLYPH or expected
local glyph, highlight, fallback = MiniIcons.get('filetype', 'nix')
assert(glyph == expected and not fallback)
assert(vim.api.nvim_get_hl(0, { name = highlight }).fg == tonumber('123456', 16))
vim.cmd('colorscheme default')
assert(vim.api.nvim_get_hl(0, { name = highlight }).fg == tonumber('123456', 16))
assert(MiniIcons.get('file', 'example.nix') == expected_file)
if expected == 'L' then
  assert(MiniIcons.get('filetype', 'glyphbook_delimiter') == ']=]')
end
print('Glyphbook Neovim checks passed')
