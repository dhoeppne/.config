return {
  "tpope/vim-fugitive",
  config = function()
  -- Set up custom keybindings for Fugitive
  vim.cmd [[
    " Open the Fugitive status window with <leader>gs
    nnoremap <leader>gs :G<CR>

    " Quickly stage files
    nnoremap <leader>ga :G add %<CR>

    " Quickly commit changes
    nnoremap <leader>gc :G commit -v<CR>

    " Quickly push to the current branch
    nnoremap <leader>gp :G push<CR>

    " Quickly view the diff of the current file
    nnoremap <leader>gd :G diff<CR>

    " Open the Fugitive blame window for the current file
    nnoremap <leader>gb :G blame<CR>

    " Open the Fugitive log window for the current branch
    nnoremap <leader>gl :G log<CR>
  ]]
  end,
}
