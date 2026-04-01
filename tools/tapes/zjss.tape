Output assets/zjss.gif

Set Theme "Catppuccin Mocha"
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
