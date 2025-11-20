# sliwez.nvim

A Neovim plugin to send content from the current buffer to configurable wezterm
panes. Based on [slimux.nvim](https://github.com/EvWilson/slimux.nvim).

## Example setup (and installation)

Via [lazy](https://github.com/folke/lazy.nvim):

```lua
require("lazy").setup({
  {
    'antonmry/sliwez.nvim', -- Update this to match your actual repository
    config = function()
      local sliwez = require('sliwez')
      sliwez.setup({
        target_pane = "1", -- wezterm pane ID
      })
      
      -- Send selected lines or current line to configured target pane
      vim.keymap.set({ 'n', 'v' }, '<leader>r', sliwez.send_lines,
        { desc = 'Send selected lines or current line to configured wezterm pane' })
        
      -- Send selected lines or current line to next pane in current tab (no configuration needed)
      vim.keymap.set({ 'n', 'v' }, '<leader>n', sliwez.send_lines_to_next_pane,
        { desc = 'Send selected lines or current line to next wezterm pane' })
    end
  }
})
```

The target pane that text is sent to is specified using wezterm's pane ID
system. You can find pane IDs using `wezterm cli list` or by checking the
`WEZTERM_PANE` environment variable in your current pane. This target pane can
be configured initially in the `setup` function shown above, but also on the
fly via the provided `configure_target_pane` function, like in the below
snippet:

```lua
:lua require('sliwez').configure_target_pane('2')
```

For more detail on wezterm pane targeting, check out the documentation:
<https://wezfurlong.org/wezterm/cli/list.html>

You can also get the current pane ID by running `echo $WEZTERM_PANE` in your
shell.

## Line Sending

The plugin provides a unified interface for sending text to wezterm panes:

- If text is visually selected (any visual mode), sends the selected lines
  (always full lines)
- If no selection, sends the current line

Main functions:
- `send_lines()` - Send selected lines or current line to configured target
  pane
- `send_lines_to_next_pane()` - Send selected lines or current line to next
  pane in current tab
- `send_lines_with_delay_ms(delay)` - Send selected lines or current line with
  character delay

## Next Pane Functionality

The plugin includes convenient functions to automatically send text to the
next pane in the current wezterm tab, without needing to know or configure
specific pane IDs.

These functions automatically:
1. Find all panes in the current tab
2. Determine the "next" pane (with wrap-around to first pane)
3. Send the text to that pane
4. Show confirmation with target pane info

## Additional Functions

```
send(text)
  Parameters:
    - text: a string of text that will be sent to the configured pane
  Description:
    This function will send text to the target pane followed by a newline.

send_to_pane(text, pane_id)
  Parameters:
    - text: a string of text that will be sent to the specified pane
    - pane_id: the target wezterm pane ID
  Description:
    This function will send text to a specific pane ID followed by a newline.

send_to_next_pane(text)
  Parameters:
    - text: a string of text that will be sent to the next pane
  Description:
    This function will send text to the next pane in the current tab followed by a newline.
    Automatically finds and targets the next pane.

send_delayed(text, delay)
  Parameters:
    - text: a string of text that will be sent to the configured pane
    - delay: a delay between each printed character, specified in milliseconds
  Description:
    This function will have the specified delay between each character sent to
    the target pane, followed by a newline.
  Note:
    THIS FUNCTION IS NOT ASYNCHRONOUS. Neovim will be frozen until the command 
    completes. Be careful with long strings and high delays.

send_lines_with_delay_ms(delay)
  Parameters:
    - delay: a delay between each printed character, specified in milliseconds
  Description:
    This function will send selected lines or current line to the configured target,
    with the given delay between each character sent. This can be useful for e.g.
    instructional applications, or a LMGTFY presentational panache.

get_wezterm_pane()
  Description:
    Returns the current wezterm pane ID from the WEZTERM_PANE environment variable.

get_current_pane_info()
  Description:
    Returns detailed information about the current wezterm pane (requires wezterm cli).

get_next_pane_in_tab()
  Description:
    Returns information about the next pane in the current wezterm tab.
```

## Compatibility/Support

This project will attempt to support the latest Neovim stable release. Issues
or incompatibilities only replicable in nightly releases, or sufficiently older
versions (>2 major versions back) will not be supported.

This plugin requires wezterm to be installed and accessible via the `wezterm
cli` command.
