# My Dotfiles - Reference Notes

Simple repo to store my dotfiles for ghostty, tmux, and oh-my-posh configs. This repo structure is designed to be used with GNU Stow. My Neovim config lives in a separate repo and can be found [here](https://github.com/isai7710/darksaber-nvim)

## GNU Stow — the mental model

Stow manages **symlinks**. Inside `~/.dotfiles`, each top-level folder is a
**package** (`tmux/`, `ghostty/`, `oh-my-posh/`). Running `stow <package>` from
inside `~/.dotfiles` recreates the folder tree found *inside* that package as
symlinks in the **parent directory** — and the parent of `~/.dotfiles` is `~`.

So: the path inside a package = the path it lands at in `$HOME`.

    tmux/.config/tmux/tmux.conf   →   ~/.config/tmux/tmux.conf  (as a symlink)

The link points back into the repo, so editing either path edits the *same file*.
That's the payoff: configs live in one version-controlled repo but appear where
each tool expects them.

### Everyday commands (run from `~/.dotfiles`)
- `stow -nv <pkg>`  - DRY RUN (simulate + verbose). Always do this first.
- `stow <pkg>`      - create the symlinks.
- `stow -D <pkg>`   - remove the symlinks (safe: only removes stow's links).
- `stow -R <pkg>`   - restow (unlink + relink). Use after moving files around.

### The golden rule
- **Edit a config file's contents** → no re-stow. Just reload that config. (The link already
  points at the repo; content changes are live instantly.)
- **Add or remove a file** → re-stow, because the *set of files* changed.

## The three config packages

| Tool        | Repo path                                        | Links to               | How it's found |
|-------------|--------------------------------------------------|------------------------|----------------|
| tmux        | `tmux/.config/tmux/tmux.conf`                    | `~/.config/tmux/tmux.conf` | tmux reads `~/.config/tmux/tmux.conf` |
| Ghostty     | `ghostty/.config/ghostty/config`                 | `~/.config/ghostty/config` | Ghostty auto-reads this path |
| oh-my-posh  | `oh-my-posh/.config/oh-my-posh/theme.toml`       | `~/.config/oh-my-posh/theme.toml` | NOT auto-found — the shell points at it explicitly via `oh-my-posh init zsh --config <path>` in `.zshrc` (see their docs for more) |


## The tmux battery script (native, no plugins)

Replaced the TPM `tmux-battery` plugin with a self-contained script that reads
macOS's native `pmset -g batt`. It lives in the repo and is committed, so it's
fully reproducible with zero setup.

- Path: `tmux/.config/tmux/scripts/battery.sh`
- Called from `status-right` via `#(~/.config/tmux/scripts/battery.sh)`
- Refreshes via `set -g status-interval 30`
- Icons use `printf` octal escapes (POSIX-safe on macOS's bash 3.2, not `\uXXXX`)

### Executable bit (`chmod +x`)
Scripts must have the **execute permission** to be run as programs.
- `-rw-r--r--` = data file (not runnable)
- `-rwxr-xr-x` = executable (the `x`'s)

Set it with executable permissions with `chmod +x battery.sh`. **Git tracks this bit** (mode `100755` vs
`100644`), so once committed it survives to every future machine - no re-chmod
after cloning. Without it, tmux's `#(...)` call for this script silently fails.
