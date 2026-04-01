Output assets/prompt.gif

Set Theme "Catppuccin Mocha"
Set FontSize 16
Set FontFamily "MesloLGS NF"
Set Width 1100
Set Height 480
Set Framerate 10
Set Padding 20
Set Shell "zsh"

# Setup: source .zshrc so p10k/aliases load; silence instant-prompt warning
Hide
Type "export POWERLEVEL9K_INSTANT_PROMPT=quiet && source ~/.zshrc 2>/dev/null; cd ~/repos/zshkit"
Enter
Sleep 3s
Type "clear"
Enter
Sleep 0.5s
Show

# Show git-aware prompt: branch, dirty indicator, command timing
Type "git log --oneline -7"
Enter
Sleep 3s

Type "git status"
Enter
Sleep 3s
