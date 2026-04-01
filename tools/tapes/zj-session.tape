Output assets/zj-session.gif

Set Theme { "name": "VSCode Dark", "background": "#1e1e1e", "foreground": "#cccccc", "cursor": "#ffffff", "black": "#000000", "brightBlack": "#666666", "red": "#cd3131", "brightRed": "#f14c4c", "green": "#0dbc79", "brightGreen": "#23d18b", "yellow": "#e5e510", "brightYellow": "#f5f543", "blue": "#2472c8", "brightBlue": "#3b8eea", "purple": "#bc3fbc", "brightPurple": "#d670d6", "cyan": "#11a8cd", "brightCyan": "#29b8db", "white": "#e5e5e5", "brightWhite": "#e5e5e5", "selectionColor": "#264f78" }
Set FontSize 16
Set FontFamily "MesloLGS NF"
Set Width 1100
Set Height 360
Set Framerate 8
Set Padding 20
Set Shell "zsh"

Hide
Type "export POWERLEVEL9K_INSTANT_PROMPT=quiet && source ~/.zshrc 2>/dev/null"
Enter
Sleep 3s
Type "clear"
Enter
Sleep 0.5s
Show

# Show the key Zellij session commands
Type "zellij list-sessions 2>/dev/null || echo 'No active sessions'"
Enter
Sleep 1.5s

Type "echo '# zj              # attach / create session named after current dir'"
Enter
Sleep 0.8s
Type "echo '# zj my-project   # attach to or create named session'"
Enter
Sleep 0.8s
Type "echo '# zjs gpu-server  # SSH and attach in one step'"
Enter
Sleep 1.5s
