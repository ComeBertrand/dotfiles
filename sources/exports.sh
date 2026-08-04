# Environment variables.
#
# Sourced by ~/.bash_profile, which bashrc.sh loads for every interactive shell —
# so new zellij panes pick these up without a relog. PATH and TMPDIR live in
# path.sh; everything else belongs here.

# Claude Code renders fullscreen in the alternate screen, which by definition has no
# scrollback: `zellij action dump-screen --full` on such a pane returns exactly the
# viewport, so Ctrl+b [ and Ctrl+b ] have nothing to page through. This forces
# normal-buffer rendering, which restores real zellij scrollback.
#
# Undocumented internal knob (found in the claude-code bundle alongside
# CLAUDE_CODE_DISABLE_VIRTUAL_SCROLL and CLAUDE_CODE_SCROLL_SPEED), so it may change
# in a future release. If scrollback breaks again after an upgrade.sh, check whether
# this variable still exists:
#   grep -ao 'CLAUDE_CODE_[A-Z_]*SCREEN[A-Z_]*' "$(readlink -f "$(command -v claude)" | xargs dirname)/.claude-wrapped" | sort -u
export CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1
