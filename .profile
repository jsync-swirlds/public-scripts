# Enable homebrew extensions
eval "$(/opt/homebrew/bin/brew shellenv)"
# Don't save command history and sessions when a shell exits, because that is a data security problem
unset HISTFILE
export SHELL_SESSION_HISTORY=0
# Save ample command history *within* a process, however
export HISTSIZE=2048
# but set history to save to a file to 0 (because shells differ on how to handle a HISTFILE not set)
export HISTFILESIZE=0

