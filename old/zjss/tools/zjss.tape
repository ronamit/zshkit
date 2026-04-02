Output assets/zjss.gif

Set Theme { "name": "VSCode Dark", "background": "#1e1e1e", "foreground": "#cccccc", "cursor": "#ffffff", "black": "#000000", "brightBlack": "#666666", "red": "#cd3131", "brightRed": "#f14c4c", "green": "#0dbc79", "brightGreen": "#23d18b", "yellow": "#e5e510", "brightYellow": "#f5f543", "blue": "#2472c8", "brightBlue": "#3b8eea", "purple": "#bc3fbc", "brightPurple": "#d670d6", "cyan": "#11a8cd", "brightCyan": "#29b8db", "white": "#e5e5e5", "brightWhite": "#e5e5e5", "selectionColor": "#264f78" }
Set FontSize 12
Set FontFamily "MesloLGS NF"
Set Width 1100
Set Height 600
Set Framerate 12
Set Padding 20
Set Shell "zsh"

Hide
Type "export POWERLEVEL9K_INSTANT_PROMPT=quiet && source ~/.zshrc 2>/dev/null"
Enter
# Movie magic: copy pre-written layout that mimics the remote SSH panes
Type "cp tools/fake-zjss.kdl /tmp/fake-zjss.kdl"
Enter
Type "clear"
Enter
Show

Type@100ms "zjss gpu-server             # 2x2 split (sessions 0,1,2,3)"
Sleep 1s
# Clear the line and launch the fake layout to bypass the SSH block
Ctrl+U
Hide
Type "zellij --layout /tmp/fake-zjss.kdl"
Enter
Show
Sleep 4s
