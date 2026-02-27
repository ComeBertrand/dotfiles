# Migration Implementation Plan — Phases 1, 2, 3, 5

Detailed implementation guidance for each remaining phase.
Phases 0 and 4 are already implemented.

---

## Phase 1: urxvt → Kitty

**Estimated time:** 1–2 hours
**Files touched:** `configuration.nix`, `sources/i3config.conf`, new `sources/kitty.conf`
**Files to leave alone for now:** `sources/tmux.conf` (will be removed with Zellij migration)

### Step 1: Add Kitty package, remove urxvt

In `configuration.nix`, in `environment.systemPackages`:

```nix
# REMOVE
rxvt-unicode-unwrapped  # Terminal

# ADD
kitty  # GPU-accelerated terminal
```

Also remove the urxvt Home Manager entry:

```nix
# REMOVE from home.file
".urxvt/ext/resize-font" = {
  source = ./sources/rxvt-resize-font;
};
```

Keep `.Xresources` for now — other X11 apps may use it. You can clean it up later.

### Step 2: Create `sources/kitty.conf`

Create a new kitty config and add the Home Manager entry:

```nix
# ADD to home.file
".config/kitty/kitty.conf" = {
  source = ./sources/kitty.conf;
};
```

The config itself — use Hermit font, and a modernized Base16-style dark color scheme.
The original xresources scheme was Base16 Default Dark by Chris Kempson. A good
successor that keeps the same subdued, dark mood but feels fresher is **Base16 Tomorrow Night**
or **Gruvbox Dark Hard** (which matches your vim/neovim colorscheme already).

Since you already use Gruvbox everywhere in vim/neovim, going Gruvbox for kitty makes
the whole stack consistent:

```conf
# sources/kitty.conf

# Font
font_family      Hermit Light
bold_font        Hermit Bold
italic_font      Hermit Light Italic
bold_italic_font Hermit Bold Italic
font_size        12.0

# Cursor
cursor_shape     block
cursor_blink_interval 0

# Scrollback
scrollback_lines 10000

# Window
window_padding_width 10
confirm_os_window_close 0
enable_audio_bell no

# Clipboard — kitty handles this natively, no xsel needed
clipboard_control write-clipboard read-clipboard

# Keyboard
map ctrl+shift+c copy_to_clipboard
map ctrl+shift+v paste_from_clipboard
map ctrl+equal  change_font_size all +2.0
map ctrl+minus  change_font_size all -2.0
map ctrl+0      change_font_size all 0

# Gruvbox Dark Hard colorscheme
# Matches your vim/neovim gruvbox theme
background #1d2021
foreground #ebdbb2
cursor     #ebdbb2

selection_background #504945
selection_foreground #ebdbb2

# Normal colors
color0  #282828
color1  #cc241d
color2  #98971a
color3  #d79921
color4  #458588
color5  #b16286
color6  #689d6a
color7  #a89984

# Bright colors
color8  #928374
color9  #fb4934
color10 #b8bb26
color11 #fabd2f
color12 #83a598
color13 #d3869b
color14 #8ec07c
color15 #fbf1c7
```

### Step 3: Update i3 config

In `sources/i3config.conf`, change the terminal launch:

```conf
# REPLACE
bindsym $mod+Return exec i3-sensible-terminal

# WITH
bindsym $mod+Return exec kitty
```

Alternatively, you can set the `TERMINAL` environment variable in `configuration.nix`:

```nix
environment.variables.TERMINAL = "kitty";
```

This lets `i3-sensible-terminal` pick it up automatically. Either approach works,
the explicit `exec kitty` is simpler and more predictable.

### Step 4: Update bash_prompt.sh terminal detection

In `sources/bash_prompt.sh`, the terminal detection block:

```bash
if [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM='gnome-256color';
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM='xterm-256color';
fi;
```

Kitty sets `TERM=xterm-kitty` by default, which is fine. The `elif` branch handles
it (falls through to `xterm-256color` if `xterm-kitty` terminfo isn't found). No
change strictly necessary, but you could add an explicit kitty case:

```bash
if [[ "$TERM" = "xterm-kitty" ]]; then
    : # Kitty sets its own TERM, leave it alone
elif [[ $COLORTERM = gnome-* && $TERM = xterm ]] && infocmp gnome-256color >/dev/null 2>&1; then
    export TERM='gnome-256color';
elif infocmp xterm-256color >/dev/null 2>&1; then
    export TERM='xterm-256color';
fi;
```

### Step 5: Verify & test

```bash
./recrank.sh
# Start kitty manually first to test
kitty &
# Check colors, font rendering, clipboard (Ctrl+Shift+C/V)
# Check i3 keybinding: Alt+Return should open kitty
```

### What NOT to touch yet

- `sources/tmux.conf` — leave `default-terminal "rxvt-256color"` as-is. This will
  be cleaned up entirely when tmux is removed in Phase 5.
- `sources/xresources` — keep around as reference. Remove when confident kitty is stable.
- `sources/rxvt-resize-font` — delete from sources/ after removing the Home Manager entry.

---

## Phase 2: git-prole worktrees

**Estimated time:** 1 hour setup + ongoing per-repo conversions
**Files touched:** `configuration.nix`, `sources/scripts/setexclude`

### Step 1: Install git-prole

In `configuration.nix`, add to `environment.systemPackages`:

```nix
git-prole  # Git worktree management
```

No flake input needed — it's in nixpkgs already.

### Step 2: Configure git worktree settings

Since you have git 2.51.2, set the recommended global config. Add to `sources/gitconfig.conf`:

```ini
[worktree]
    useRelativePaths = false
```

### Step 3: Fix setexclude for worktrees

Replace the `EXCLUDE_PATH` line in `sources/scripts/setexclude`:

```bash
# REPLACE
EXCLUDE_PATH=$PWD/.git/info/exclude

# WITH
EXCLUDE_PATH=$(git rev-parse --git-common-dir)/info/exclude
```

`git rev-parse --git-common-dir` returns:
- `.git` in a regular repo (same behavior as before)
- `.bare` (or equivalent) in a worktree setup (correct path)

The rest of the script stays identical — the patterns it adds are shared across
worktrees, which is exactly what you want.

### Step 4: Converting repos (per-repo, ongoing)

For each project you want to convert:

```bash
cd ~/projects
git prole convert my-project
```

This restructures to:

```
my-project/
├── .bare/
├── .git           # file → .bare
├── main/          # worktree (your current branch)
│   ├── .envrc     # nix-direnv picks this up per worktree
│   ├── shell.nix
│   └── ...
```

After converting:

```bash
cd my-project/main     # you're now in the default worktree
git prole add feature-x # creates my-project/feature-x/ worktree
```

**Direnv compatibility:** Your `sources/direnvrc.sh` `start-venv` function uses
`$PWD/.venv` as default, so each worktree gets its own isolated venv automatically.
No changes needed there.

**What to watch out for:**
- Bookmarks, shell history, IDE recent files — all paths change from
  `~/projects/my-project/` to `~/projects/my-project/main/`
- Convert one repo at a time, work with it for a day before converting more
- Don't convert repos with active uncommitted work — commit or stash first

### Step 5: Apply & test

```bash
./recrank.sh
# Test setexclude in a regular repo first
cd /tmp && git init test-repo && cd test-repo
setexclude
cat .git/info/exclude  # should show the patterns

# Then test with a converted worktree
git prole convert some-test-project
cd some-test-project/main
setexclude
cat $(git rev-parse --git-common-dir)/info/exclude  # should work
```

---

## Phase 3: Rofi + project context switching

**Estimated time:** 2–3 hours
**Depends on:** Phase 1 (kitty) and Phase 2 (git-prole) recommended first
**Files touched:** `configuration.nix`, `sources/i3config.conf`, new `sources/scripts/devctx`, new `sources/rofi-config.rasi`

### Step 1: Install rofi

In `configuration.nix`, add to `environment.systemPackages`:

```nix
rofi  # Application launcher (dmenu replacement)
```

### Step 2: Create rofi config

Create `sources/rofi-config.rasi` — a Gruvbox-themed config to match the rest of the stack:

```rasi
/* sources/rofi-config.rasi */
configuration {
    modi: "drun,run,window";
    show-icons: true;
    terminal: "kitty";
    font: "Hermit 12";
}

* {
    bg:       #1d2021;
    bg-alt:   #282828;
    fg:       #ebdbb2;
    accent:   #458588;
    urgent:   #cc241d;

    background-color: @bg;
    text-color:       @fg;
}

window {
    width:            30%;
    border:           2px;
    border-color:     @accent;
    border-radius:    0px;
    padding:          10px;
}

inputbar {
    children:         [ prompt, entry ];
    padding:          8px;
    background-color: @bg-alt;
}

prompt {
    padding:          0 8px 0 0;
    text-color:       @accent;
}

listview {
    lines:            8;
    scrollbar:        false;
    padding:          4px 0;
}

element {
    padding:          6px 8px;
}

element selected {
    background-color: @accent;
    text-color:       @bg;
}
```

Add Home Manager entry in `configuration.nix`:

```nix
".config/rofi/config.rasi" = {
  source = ./sources/rofi-config.rasi;
};
```

### Step 3: Update i3 config — replace dmenu with rofi

In `sources/i3config.conf`:

```conf
# REPLACE
bindsym $mod+d exec --no-startup-id dmenu_run

# WITH
bindsym $mod+d exec --no-startup-id rofi -show drun
```

You can also remove `dmenu` from the i3 extraPackages in `configuration.nix`
(under `windowManager.i3.extraPackages`) once you're comfortable rofi works.

### Step 4: Create the devctx project switcher

This is the big one. Create `sources/scripts/devctx`:

```bash
#!/usr/bin/env bash
# devctx - Open a development context (project + worktree) in kitty
#
# Scans project directories for git worktrees (git-prole style)
# and regular repos, lets you pick one via rofi, and opens a kitty
# window in that directory.
#
# Usage: devctx
# Typically bound to an i3 keybinding.

set -euo pipefail

PROJECT_DIRS=("$HOME/projects" "$HOME/work")
# Add more project root directories above as needed

# Gather all candidate directories
candidates=()
for root in "${PROJECT_DIRS[@]}"; do
    [[ -d "$root" ]] || continue
    for project in "$root"/*/; do
        [[ -d "$project" ]] || continue
        # Check if this is a git-prole bare repo (has .bare/)
        if [[ -d "${project}.bare" ]]; then
            # List worktrees
            for wt in "$project"*/; do
                [[ -d "$wt/.git" || -f "$wt/.git" ]] || continue
                candidates+=("$wt")
            done
        elif [[ -d "${project}.git" ]]; then
            # Regular git repo
            candidates+=("$project")
        fi
    done
done

if [[ ${#candidates[@]} -eq 0 ]]; then
    notify-send "devctx" "No projects found"
    exit 1
fi

# Format for display: show relative to home
display=()
for c in "${candidates[@]}"; do
    display+=("${c/#$HOME\//~/}")
done

# Pick via rofi
selected=$(printf '%s\n' "${display[@]}" | rofi -dmenu -p "project" -i)
[[ -z "$selected" ]] && exit 0

# Expand ~ back
target="${selected/#\~/$HOME}"

# Open kitty in that directory with vim
# Uses kitty's --directory flag and launches vim as the initial command
kitty --directory "$target" --title "dev: $(basename "$(dirname "$target")")/$(basename "$target")" &

disown
```

**Note:** The script launches `vim` is NOT auto-started — it just opens kitty in the
project directory so you can choose what to do. If you want vim to auto-launch, change
the kitty line to:

```bash
kitty --directory "$target" --title "dev: ..." vim &
```

### Step 5: Bind devctx in i3

In `sources/i3config.conf`, repurpose or add a keybinding:

```conf
# REPLACE (or add alongside)
bindsym $mod+Shift+d exec --no-startup-id ~/.local/bin/screenz

# ADD
bindsym $mod+p exec --no-startup-id ~/.local/bin/devctx
```

Keep `$mod+Shift+d` for screenz. Use `$mod+p` (for "project") or another free binding.

### Step 6: Apply & test

```bash
./recrank.sh
chmod +x sources/scripts/devctx
# Test rofi standalone
rofi -show drun
# Test devctx
devctx
```

### Future improvements (not now)

- **dcs integration:** Once dcs is refactored for worktrees, devctx could optionally
  start Docker Compose services for the selected project. Keep this separate for now.
- **Session memory:** Track last-used project and pre-select it in rofi.
- **Multiple monitors:** Use `i3-msg` to move the new kitty window to a specific workspace.

---

## Phase 5: Zellij (low priority, when ready)

**Estimated time:** 3+ hours
**Depends on:** Phase 1 (kitty must be stable)
**Files touched:** `configuration.nix`, `sources/tmux.conf` (removed), new `sources/zellij/config.kdl`, vim config, neovim config

This is outlined at a higher level since it's not immediate. Do this after
Phases 1–3 are stable and you've been using kitty for a while.

### Step 1: Install zellij, keep tmux temporarily

In `configuration.nix`:

```nix
# ADD (keep tmux alongside for transition)
zellij  # Terminal multiplexer (tmux replacement)
```

### Step 2: Create zellij config

Create `sources/zellij/config.kdl`. Zellij uses KDL format.

Key decisions for the config:

**Keybinding mode:** Zellij uses a different paradigm than tmux. Instead of a prefix
key (`Ctrl+b`), it has modal keybindings (Normal, Locked, Pane, Tab, etc.).
The most tmux-like experience uses `Ctrl+a` or `Ctrl+b` as the switch-mode key:

```kdl
// sources/zellij/config.kdl
keybinds {
    // Use Ctrl+b as the "prefix" equivalent (switch to pane mode)
    normal {
        bind "Ctrl b" { SwitchToMode "pane"; }
    }
    pane {
        bind "h" { MoveFocus "left"; SwitchToMode "normal"; }
        bind "j" { MoveFocus "down"; SwitchToMode "normal"; }
        bind "k" { MoveFocus "up"; SwitchToMode "normal"; }
        bind "l" { MoveFocus "right"; SwitchToMode "normal"; }
        bind "|" { NewPane "right"; SwitchToMode "normal"; }
        bind "-" { NewPane "down"; SwitchToMode "normal"; }
    }
}

theme "gruvbox-dark"

default_shell "bash"
pane_frames false
```

**Session persistence:** Zellij has built-in session management:
```bash
zellij attach my-project  # attach or create
zellij list-sessions      # see what's running
```

### Step 3: Vim/Neovim navigator integration

This is the hardest part. The `christoomey/vim-tmux-navigator` plugin only works
with tmux. For Zellij, you need a different approach.

**Option A: Use Zellij's built-in vim-aware navigation** (experimental, check
if available in your Zellij version). Zellij has been working on `move-focus-or-tab`
actions that can detect vim.

**Option B: Use a Zellij plugin.** Search for `zellij-nav.wasm` or similar
community plugins that replicate the vim-tmux-navigator behavior.

**Option C: Keep Ctrl+h/j/k/l for vim splits only**, use Zellij's own keybindings
(modal, e.g. `Ctrl+b` then `h/j/k/l`) for pane navigation. This avoids conflicts
entirely but means different muscle memory for vim splits vs zellij panes.

In vim (`sources/vimrc`):
- Remove `christoomey/vim-tmux-navigator` plugin
- Remove the `is_vim` tmux detection block
- Keep the basic `Ctrl+h/j/k/l` window navigation mappings (they work for vim splits)

In neovim (`sources/nvim/lua/plugins/init.lua`):
- Remove the `christoomey/vim-tmux-navigator` plugin entry
- Replace with Zellij-compatible navigator if Option B is chosen
- Or keep basic split navigation and use modal Zellij keybindings

### Step 4: Remove tmux config

Once confident Zellij works:

```nix
# REMOVE from user packages
tmux

# REMOVE from home.file
".tmux.conf" = {
  source = ./sources/tmux.conf;
};
```

Delete `sources/tmux.conf` from the repo.

### Step 5: Update devctx (Phase 3) to use Zellij sessions

If Phase 3 is already done, update `devctx` to optionally attach/create a
Zellij session:

```bash
# Instead of just opening kitty:
session_name=$(basename "$target")
kitty --directory "$target" zellij attach "$session_name" --create &
```

This gives you persistent, named sessions per project — the main win of Zellij
over bare kitty windows.

### The nix-direnv issue you mentioned

You said tmux "breaks with nix-direnv & vim." This is likely because tmux inherits
the environment at session creation time and doesn't re-evaluate direnv when you
`cd` into a project within an existing tmux session. Zellij has the same
fundamental behavior — the multiplexer shell inherits the parent environment.

The fix (for any multiplexer) is ensuring direnv's bash hook runs in each new
pane's shell. Since your `bashrc.sh` already has `eval "$(direnv hook bash)"`,
new Zellij panes should pick up direnv correctly as long as they start a login
shell. Test this explicitly before removing tmux.

---

## Execution order recap

```
Phase 0 ✅ (done — llm-agents.nix)
Phase 4 ✅ (done — Claude Code notifications)
Phase 1 ✅ (done — kitty terminal)
Phase 2 ✅ (done — git-prole worktrees)
Phase 3 ✅ (done — rofi + devctx)
Phase 5    (zellij — whenever you're ready, ~3+ hrs)
```
