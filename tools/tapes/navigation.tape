Output assets/navigation.gif

Set Theme "Catppuccin Mocha"
Set FontSize 16
Set FontFamily "MesloLGS NF"
Set Width 1100
Set Height 380
Set Framerate 8
Set Padding 20
Set Shell "zsh"

Hide
Type "export POWERLEVEL9K_INSTANT_PROMPT=quiet && source ~/.zshrc 2>/dev/null"
Enter
Sleep 3s
Type "zoxide add $HOME/repos/zshkit $HOME/.config/kitty $HOME/.config/zellij"
Enter
Sleep 0.5s
Type "clear"
Enter
Sleep 0.5s
Show

# cd with Tab menu — arrow keys to select
Type@160ms "cd ~/.config/"
Tab
Sleep 1.5s
Down
Sleep 0.5s
Down
Sleep 0.5s
Down
Sleep 0.5s
Enter
Sleep 0.8s

Type "cd ~"
Enter
Sleep 0.3s
Type "clear"
Enter
Sleep 0.3s

# z — jump by partial name, no full path needed
Type@160ms "z zsh"
Enter
Sleep 0.6s

Type@160ms "z kitty"
Enter
Sleep 1.5s
