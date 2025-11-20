# Markdown-Oxide Neovim profile

Standalone Neovim profile dedicated to the
[Feel-ix-343/markdown-oxide](https://github.com/Feel-ix-343/markdown-oxide)
language server. It bundles Oil (directory view), Telescope (fuzzy search),
Lspsaga (enhanced LSP UI), nvim-cmp (completion), Mason + LSP config, and the
light `dawnfox` theme.

## Getting started with Obsidian vaults

1. **Keep this repo anywhere** you want the isolated profile to live. All Neovim
   data (plugins, caches, configs) stay inside it.
2. **Launch the helper**: `./obs.sh --vault
   /path/to/MyVault [file.md]`. The
   script sets `NVIM_APPNAME=markdown-oxide-nvim` plus dedicated XDG directories
   and `cd`s into the vault so `markdown-oxide` roots itself from the directory
   that contains `.obsidian`, `.moxide.toml`, or `.git`.
3. **First run**: let `lazy.nvim` finish installing plugins, then restart or run
   `:Lazy sync`. Mason automatically downloads the `markdown_oxide` binary;
   monitor `:Mason` if the install needs attention or install manually with
   Cargo.
4. **Daily note format**: the repo ships with `moxide/settings.toml` (picked up
   via the custom XDG config dir) that sets `dailynote = "%Y-%m-%d"`, so
   commands such as `:Daily today` create `2025-11-20.md` style files. Adjust
   the file if you prefer a different pattern.
5. **Open notes** from the vault using Oil or Telescope. Once the language
   server attaches you can use PKM features (backlinks, daily notes, code
   actions, diagnostics, etc.). Drop a `.moxide.toml` into your vault if you
   need to customize Markdown-Oxide settings (daily note format, new note
   folder, etc.).

## Everyday workflow

- Run the script with `--vault` whenever you want to work on an Obsidian vault
  in Neovim (plugins, caches, and state stay inside this repo thanks to the
  custom XDG paths).
- Keep Neovim open while editing to let the server maintain its index of links
  and tags.
- Use `:Daily` to open natural-language daily notes (e.g. `:Daily next monday`,
  `:Daily -3`); results will follow the ISO format defined in
  `moxide/settings.toml`.
- Occasionally open `:Mason` to update or reinstall the `markdown_oxide` binary.
- Because everything lives under this project, your default Neovim setup stays
  untouched.

## Convenient shell alias

Add an alias to your shell configuration (e.g. `~/.bashrc`, `~/.zshrc`) so you
can jump into your vault from anywhere:

```sh
alias moxide="$HOME/Workspace/Galiglobal/test/obs.sh --vault $HOME/Notes"
```

Reload your shell (`source ~/.bashrc`) and run `moxide journal/today.md` to open
files directly. Adjust the paths to point to this repo and your vault.

## Shortcut reference

Leader key = `<Space>`.

### Navigation and search

- `-`: Oil file browser rooted at the current file's directory
- `<leader>ff`: Telescope find files (respects `.gitignore` if present)
- `<leader>fg`: Telescope live grep
- `<leader>fb`: Telescope buffers
- `<leader>fh`: `:Telescope help_tags` (type search term to read docs)
- `:Oil` or `:Telescope oldfiles` for quick manual invocations

### LSP / PKM helpers

- `gh`: Lspsaga finder (definitions, references, implementations)
- `gd`: Lspsaga goto definition (jumps into the current link/heading)
- `gp`: Lspsaga peek definition
- `<leader>lr`: Lspsaga rename symbol
- `<leader>ld`: Lspsaga show line diagnostics
- `<leader>lo`: Lspsaga outline
- `:Daily [when]`: Markdown-Oxide LSP command for daily notes
- `:Lspsaga code_action`: apply code actions (e.g. create note for unresolved
  link)
- `:Lspsaga term_toggle`: drop into a floating terminal for ad-hoc commands
- Native LSP motions still work: `gd` (goto definition), `gr` (references), `K`
  (hover docs), `[d` / `]d` (cycle diagnostics)

### Completion

- `<C-Space>` (insert mode): trigger nvim-cmp completion menu
- `<CR>`: confirm the current completion item
- `<Tab>` / `<S-Tab>`: move through the completion list when it is visible

### Maintenance commands

- `:Lazy`, `:Lazy sync`: inspect/update plugins
- `:Mason`: manage external binaries (watch `markdown_oxide` there)
- `:checkhealth`: verify dependencies if something misbehaves
- `:messages`: review any startup warnings

Feel free to extend this profile further, but keeping it separate ensures a
clean, Obsidian-focused Neovim experience.
