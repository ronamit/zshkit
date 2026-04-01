Output assets/autosuggest.gif

Set Theme { "name": "VSCode Dark", "background": "#1e1e1e", "foreground": "#cccccc", "cursor": "#ffffff", "black": "#000000", "brightBlack": "#666666", "red": "#cd3131", "brightRed": "#f14c4c", "green": "#0dbc79", "brightGreen": "#23d18b", "yellow": "#e5e510", "brightYellow": "#f5f543", "blue": "#2472c8", "brightBlue": "#3b8eea", "purple": "#bc3fbc", "brightPurple": "#d670d6", "cyan": "#11a8cd", "brightCyan": "#29b8db", "white": "#e5e5e5", "brightWhite": "#e5e5e5", "selectionColor": "#264f78" }
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
