Output assets/zjss.gif

Set Theme { "name": "VSCode Dark", "background": "#1e1e1e", "foreground": "#cccccc", "cursor": "#ffffff", "black": "#000000", "brightBlack": "#666666", "red": "#cd3131", "brightRed": "#f14c4c", "green": "#0dbc79", "brightGreen": "#23d18b", "yellow": "#e5e510", "brightYellow": "#f5f543", "blue": "#2472c8", "brightBlue": "#3b8eea", "purple": "#bc3fbc", "brightPurple": "#d670d6", "cyan": "#11a8cd", "brightCyan": "#29b8db", "white": "#e5e5e5", "brightWhite": "#e5e5e5", "selectionColor": "#264f78" }
Set FontSize 16
Set FontFamily "MesloLGS NF"
Set Width 900
Set Height 380
Set Framerate 6
Set PlaybackSpeed 3
Set Padding 20
Set Shell "zsh"

Hide
Type "export POWERLEVEL9K_INSTANT_PROMPT=quiet && source ~/.zshrc 2>/dev/null"
Enter
Sleep 3s
Type "clear"
Enter
Sleep 0.5s
Set PlaybackSpeed 1
Show

Type "echo '# SSH into 4 sessions on the same host in a 2x2 split:'"
Enter
Sleep 0.8s
Type "echo '  zjss myserver               # sessions 0 1 2 3 (default)'"
Enter
Sleep 0.6s
Type "echo '  zjss myserver train eval    # 2-pane side-by-side'"
Enter
Sleep 0.6s
Type "echo '  zjss myserver a b c d       # 2x2 with custom session names'"
Enter
Sleep 0.8s
Type "echo ''"
Enter
Sleep 0.2s
Type "echo '  ┌─────────────┬─────────────┐'"
Enter
Sleep 0.3s
Type "echo '  │  0@mysrv  │  1@mysrv  │'"
Enter
Sleep 0.3s
Type "echo '  ├─────────────┼─────────────┤'"
Enter
Sleep 0.3s
Type "echo '  │  2@mysrv  │  3@mysrv  │'"
Enter
Sleep 0.3s
Type "echo '  └─────────────┴─────────────┘'"
Enter
Sleep 2s
