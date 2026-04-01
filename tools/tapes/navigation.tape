Output assets/navigation.gif

Set Theme { "name": "VSCode Dark", "background": "#1e1e1e", "foreground": "#cccccc", "cursor": "#ffffff", "black": "#000000", "brightBlack": "#666666", "red": "#cd3131", "brightRed": "#f14c4c", "green": "#0dbc79", "brightGreen": "#23d18b", "yellow": "#e5e510", "brightYellow": "#f5f543", "blue": "#2472c8", "brightBlue": "#3b8eea", "purple": "#bc3fbc", "brightPurple": "#d670d6", "cyan": "#11a8cd", "brightCyan": "#29b8db", "white": "#e5e5e5", "brightWhite": "#e5e5e5", "selectionColor": "#264f78" }
Set FontSize 16
Set FontFamily "MesloLGS NF"
Set Width 1100
Set Height 460
Set Framerate 8
Set Padding 20
Set Shell "zsh"

Hide
Type "export POWERLEVEL9K_INSTANT_PROMPT=quiet && source ~/.zshrc 2>/dev/null"
Enter
Sleep 3s
# Prime cd history with realistic paths
Type "cd $HOME/.config/kitty && cd $HOME/.config/zellij && cd $HOME/repos/zshkit && cd $HOME"
Enter
Sleep 0.5s
Type "zoxide add $HOME/repos/zshkit $HOME/.config/kitty $HOME/.config/zellij"
Enter
Sleep 0.5s
Type "clear"
Enter
Sleep 0.5s
Show

# 1. Down after cd → opens directory completion menu (navigate with arrows)
Type@160ms "cd ~/.config/"
Down
Sleep 2s
Down
Sleep 0.5s
Down
Sleep 0.5s
Enter
Sleep 0.8s

Type "clear"
Enter
Sleep 0.3s

# 2. Up → history search; Down → forward through history
Type@160ms "cd ~/.c"
Up
Sleep 0.6s
Up
Sleep 0.6s
Down
Sleep 0.6s
Enter
Sleep 0.8s

# .. to go up
Type@160ms ".."
Enter
Sleep 0.4s
Type "clear"
Enter
Sleep 0.3s

# 3. z — jump by keyword
Type@160ms "z zsh"
Enter
Sleep 0.6s
Type@160ms "z kitty"
Enter
Sleep 1.5s
