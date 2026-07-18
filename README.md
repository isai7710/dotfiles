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
- `stow -nv <pkg>`  — DRY RUN (simulate + verbose). Always do this first.
- `stow <pkg>`      — create the links.
- `stow -D <pkg>`   — remove the links (safe: only removes stow's links).
- `stow -R <pkg>`   — restow (unlink + relink). Use after moving files around.

### The golden rule
- **Edit a file's contents** → no re-stow. Just reload the app. (The link already
  points at the repo; content changes are live instantly.)
- **Add or remove a file** → re-stow, because the *set of files* changed.

## The three config packages

| Tool        | Repo path                                        | Links to               | How it's found |
|-------------|--------------------------------------------------|------------------------|----------------|
| tmux        | `tmux/.config/tmux/tmux.conf`                    | `~/.config/tmux/tmux.conf` | tmux reads `~/.config/tmux/tmux.conf` |
| Ghostty     | `ghostty/.config/ghostty/config`                 | `~/.config/ghostty/config` | Ghostty auto-reads this path |
| oh-my-posh  | `oh-my-posh/.config/oh-my-posh/theme.toml`       | `~/.config/oh-my-posh/theme.toml` | NOT auto-found — the shell points at it explicitly via `oh-my-posh init zsh --config <path>` in `.zshrc` |

Repo-root files (`Brewfile`, `README.md`, `docs/`) are **not** packages — Stow
only touches folders you name, so they're never symlinked. Correct.

## The tmux battery script (native, no plugins)

Replaced the TPM `tmux-battery` plugin with a self-contained script that reads
macOS's native `pmset -g batt`. It lives in the repo and is committed, so it's
fully reproducible with zero setup.

- Path: `tmux/.config/tmux/scripts/battery.sh`
- Called from `status-right` via `#(~/.config/tmux/scripts/battery.sh)`
- Refreshes via `set -g status-interval 30`
- Icons use `printf` octal escapes (POSIX-safe on macOS's bash 3.2, not `\uXXXX`)

**Catppuccin was never tied to TPM** — it's a manual `run` of a hand-cloned file
(`~/.config/tmux/plugins/catppuccin/...`). Removing TPM left the theme untouched;
it only removed the battery plugin, which the script now replaces.

### Executable bit (`chmod +x`)
Scripts must have the **execute permission** to be run as programs.
- `-rw-r--r--` = data file (not runnable)
- `-rwxr-xr-x` = executable (the `x`'s)

Set it with `chmod +x battery.sh`. **Git tracks this bit** (mode `100755` vs
`100644`), so once committed it survives to every future machine — no re-chmod
after cloning. Without it, tmux's `#(...)` call silently fails.

## The symlink incident (what went wrong, and the lesson)

**What happened:** `rm ~/.config/tmux/scripts/battery.sh` deleted the file from
the *repo* too.

**Why:** `~/.config/tmux/scripts` was a **folded** symlink — Stow had linked the
entire `scripts` *directory* as one link into the repo (this happens when the
parent dir doesn't already exist as a real directory). So the path resolved
*through* the directory link and `rm` hit the real repo file.

**Recovery:** the file was committed, so `git restore <path>` brought it back.
(This is the whole point of committing configs — every state is a `git restore`
away.)

**The fix (unfolding):** create the parent as a REAL directory before stowing,
which forces file-level links instead of a folded directory link:

    stow -D tmux
    mkdir -p ~/.config/tmux/scripts    # real dir → stow can't fold it
    stow tmux

After: `scripts/` is a real directory and `battery.sh` is an individual
file-link. Now `rm` on it removes only the link, not the repo file.

### Rules to avoid a repeat
1. **Before deleting anything under `~/.config`, run `ls -la` and look for `->`.**
   An arrow means it's a link into your repo — treat with care.
2. **Never raw-`rm` stow-managed paths.** Use `stow -D <pkg>` — it removes only
   stow's links, never the repo target or real content (like `plugins/`).
3. **Pre-create shared config dirs as real directories** (`mkdir -p ~/.config/<tool>`)
   before stowing, so Stow links files individually instead of folding the dir.
   Especially where a dir holds mixed content (e.g. `~/.config/tmux/` also holds
   the real `plugins/`).
4. **Commit early.** A committed file is always recoverable.
