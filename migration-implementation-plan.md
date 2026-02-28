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

## Phase 5: Finish Zellij migration + jj workspaces

**Estimated time:** 2–3 hours
**Files touched:** `configuration.nix`, `sources/tmux.conf` (removed), `sources/vimrc`, `sources/scripts/devctx`, new `sources/scripts/devwork`

### Current state

Most of Phase 5 is already done:
- ✅ Zellij installed and configured (`sources/zellij.kdl`, layouts, autolock)
- ✅ Neovim migrated to `zellij-nav.nvim` (Ctrl+h/j/k/l works across panes)
- ✅ Jujutsu installed (replaces git-prole worktrees)
- ✅ Tmux removed (package, config, vim plugins)
- ⬜ devctx opens bare kitty windows (no zellij sessions)
- ⬜ No jj workspace integration

### Step 1: Remove tmux from Vim

In `sources/vimrc`, remove the tmux-specific plugins:

```vim
" REMOVE these two plugins (Section 9: Plugin Manager)
Plug 'christoomey/vim-tmux-navigator'   " Seamless nav between Vim/tmux splits
Plug 'benmills/vimux'                   " Run commands in tmux pane from Vim
```

Keep the basic `Ctrl+h/j/k/l` window navigation mappings — they still work for
vim splits within a single vim instance. The zellij-autolock plugin handles the
zellij↔vim boundary (locks zellij when vim is focused, so Ctrl+h/j/k/l goes
to vim; unlocks when vim exits, so Ctrl+h/j/k/l goes to zellij).

Also remove any tmux-related comments (lines 428, 646 area).

### Step 2: Remove tmux package and config

In `configuration.nix`:

```nix
# REMOVE from user packages
tmux  # terminal multiplexer

# REMOVE from home.file
".tmux.conf" = {
  source = ./sources/tmux.conf;
};
```

Delete `sources/tmux.conf` from the repo.

### Step 3: Update devctx to use Zellij sessions

Replace the bare `kitty` launch with `zellij attach --create` so each project
gets a persistent, named session. Session name = directory basename.

```bash
# REPLACE the kitty launch line in sources/scripts/devctx:

# Current:
kitty --directory "$target" --title "dev: ..." &

# With:
session_name=$(basename "$target")
kitty --directory "$target" --title "dev: $session_name" zellij attach "$session_name" --create &
```

This means:
- First open: creates a new zellij session in that directory
- Subsequent opens: reattaches to the existing session (all panes/tabs preserved)
- `zellij list-sessions` shows all active project sessions

### Step 4: Teach devctx to discover jj workspaces

Jujutsu workspaces are directories with a `.jj/` directory. When you create a
workspace with `jj workspace add ../my-project--feature-x`, it becomes a sibling
directory to the original repo. devctx should find these too.

Update the candidate scanning in `sources/scripts/devctx`:

```bash
# REPLACE the candidate scanning loop with:
candidates=()
for root in "${PROJECT_DIRS[@]}"; do
    [[ -d "$root" ]] || continue
    for project in "$root"/*/; do
        [[ -d "$project" ]] || continue
        # Regular git repo or jj workspace
        if [[ -d "${project}.git" || -d "${project}.jj" ]]; then
            candidates+=("$project")
        fi
    done
done
```

This catches:
- Regular git repos (`.git/` directory)
- Jujutsu-colocated repos (have both `.git/` and `.jj/`)
- Jj workspaces created as siblings (`jj workspace add ../name`)

### Step 5: Create `devwork` script

New script `sources/scripts/devwork` — creates a jj workspace + zellij session
in one shot, and cleans up when done.

```bash
#!/usr/bin/env bash
# devwork - Create/open a jj workspace with a zellij session, or clean up
#
# Usage:
#   devwork <name>          Create workspace + open zellij session
#   devwork --done <name>   Clean up workspace + kill session

set -euo pipefail

usage() {
    echo "Usage: devwork <name> | devwork --done <name>"
    exit 1
}

[[ $# -lt 1 ]] && usage

# Must be in a jj repo
if ! jj root &>/dev/null; then
    echo "devwork: error: not in a jj repository" >&2
    exit 1
fi

project=$(basename "$(jj root)")

if [[ "$1" == "--done" ]]; then
    [[ -z "${2:-}" ]] && usage
    name="$2"
    workspace_dir="$(dirname "$(jj root)")/${project}--${name}"
    session_name="${project}--${name}"

    # Kill zellij session if running
    if zellij list-sessions 2>/dev/null | grep -q "^${session_name}"; then
        zellij kill-session "$session_name"
        echo "killed session: $session_name"
    fi

    # Forget jj workspace
    if jj workspace list | grep -q "^${name}:"; then
        jj workspace forget "$name"
        echo "forgot workspace: $name"
    fi

    # Remove directory
    if [[ -d "$workspace_dir" ]]; then
        rm -rf "$workspace_dir"
        echo "removed: $workspace_dir"
    fi

    echo "devwork: cleaned up '$name'"
else
    name="$1"
    workspace_dir="$(dirname "$(jj root)")/${project}--${name}"
    session_name="${project}--${name}"

    # Create workspace if it doesn't exist
    if [[ ! -d "$workspace_dir" ]]; then
        jj workspace add --name "$name" "$workspace_dir"
        echo "created workspace: $workspace_dir"
    else
        echo "workspace exists: $workspace_dir"
    fi

    # Open kitty + zellij session
    kitty --directory "$workspace_dir" --title "dev: $session_name" \
        zellij attach "$session_name" --create &
    disown

    echo "devwork: opened '$name'"
fi
```

**Workflow:**

```bash
cd ~/Workspace/my-project           # main repo
devwork feature-x                    # creates ../my-project--feature-x/
                                     # opens kitty + zellij session "my-project--feature-x"

# ... work on feature, detach zellij, come back later ...
# devctx shows both my-project and my-project--feature-x in rofi

# When done:
devwork --done feature-x             # kills session, forgets workspace, removes dir
```

**Directory convention:** `<project>--<workspace>` as siblings. The `--` separator
avoids collisions with project names that contain hyphens. devctx finds these
automatically since they have `.jj/` directories.

**Direnv compatibility:** Each workspace is a full working copy, so `.envrc` and
`shell.nix` from the repo are present. Direnv evaluates per-directory, so each
workspace gets its own nix environment and venv.

### Step 6: Verify & test

```bash
./recrank.sh

# 1. Verify tmux removal
which tmux  # should fail
vim  # Ctrl+h/j/k/l should still navigate vim splits

# 2. Test devctx with zellij sessions
devctx  # pick a project, verify zellij starts
# Ctrl+b d to detach, run devctx again — should reattach

# 3. Test jj workspace flow
cd ~/Workspace/some-jj-repo
devwork test-feature    # creates workspace + session
jj workspace list       # shows default + test-feature
devctx                  # should show both in rofi
devwork --done test-feature  # cleans up
```

---

## Execution order recap

```
Phase 0 ✅ (done — llm-agents.nix)
Phase 4 ✅ (done — Claude Code notifications)
Phase 1 ✅ (done — kitty terminal)
Phase 2 ✅ (done — git-prole → replaced by jujutsu)
Phase 3 ✅ (done — rofi + devctx)
Phase 5    (finish zellij + jj workspaces — ~2-3 hrs)
```
