Output assets/prompt.gif

Set Theme { "name": "VSCode Dark", "background": "#1e1e1e", "foreground": "#cccccc", "cursor": "#ffffff", "black": "#000000", "brightBlack": "#666666", "red": "#cd3131", "brightRed": "#f14c4c", "green": "#0dbc79", "brightGreen": "#23d18b", "yellow": "#e5e510", "brightYellow": "#f5f543", "blue": "#2472c8", "brightBlue": "#3b8eea", "purple": "#bc3fbc", "brightPurple": "#d670d6", "cyan": "#11a8cd", "brightCyan": "#29b8db", "white": "#e5e5e5", "brightWhite": "#e5e5e5", "selectionColor": "#264f78" }
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
