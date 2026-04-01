Output assets/autosuggest.gif

Set Theme "Catppuccin Mocha"
Set FontSize 16
Set FontFamily "MesloLGS NF"
Set Width 1100
Set Height 420
Set Framerate 10
Set Padding 20
Set Shell "zsh"

Hide
Type "export POWERLEVEL9K_INSTANT_PROMPT=quiet && source ~/.zshrc 2>/dev/null; cd ~/repos/zshkit"
Enter
Sleep 3s
# Build up history so suggestions have something to match
Type "cd ~/.config/kitty"
Enter
Sleep 0.3s
Type "cd ~/.config/zellij"
Enter
Sleep 0.3s
Type "cd ~/repos/zshkit"
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

# 1. Gray suggestion appears as you type; Right arrow accepts it
Type@180ms "git log"
Sleep 1.2s
# suggestion shows " --oneline -5" in gray — press Right to accept
Right
Sleep 0.5s
Enter
Sleep 2s

Type "clear"
Enter
Sleep 0.5s

# 2. Press Down arrow on a partial cd to cycle through recent directories
Type@180ms "cd ~/."
Sleep 0.8s
Down
Sleep 0.8s
Down
Sleep 0.8s
Down
Sleep 0.8s
# Accept whatever is shown
Right
Sleep 0.5s
Enter
Sleep 1.5s
