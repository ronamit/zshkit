Output assets/history-search.gif

Set Theme "Catppuccin Mocha"
Set FontSize 16
Set FontFamily "MesloLGS NF"
Set Width 1100
Set Height 500
Set Framerate 10
Set Padding 20
Set Shell "zsh"

Hide
Type "export POWERLEVEL9K_INSTANT_PROMPT=quiet && source ~/.zshrc 2>/dev/null; cd ~/repos/zshkit"
Enter
Sleep 3s
# Build up history with realistic commands so fzf has something useful to show
Type "git log --oneline -10"
Enter
Sleep 0.3s
Type "git status"
Enter
Sleep 0.3s
Type "git diff HEAD~1"
Enter
Sleep 0.3s
Type "ls -la"
Enter
Sleep 0.3s
Type "cat README.md"
Enter
Sleep 0.3s
Type "grep -r 'zellij' . --include='*.sh' -l"
Enter
Sleep 0.3s
Type "git log --oneline -5"
Enter
Sleep 0.3s
Type "git status"
Enter
Sleep 0.3s
Type "clear"
Enter
Sleep 0.5s
Show

# Ctrl+R opens fzf over full shell history
Ctrl+R
Sleep 1s

# Fuzzy filter — results narrow as you type
Type@150ms "git log"
Sleep 2s

# Navigate to a different match
Down
Sleep 0.8s
Down
Sleep 0.8s

# Accept selection
Enter
Sleep 2s
