Output assets/navigation.gif

Set Theme "Catppuccin Mocha"
Set FontSize 16
Set FontFamily "MesloLGS NF"
Set Width 1100
Set Height 480
Set Framerate 10
Set Padding 20
Set Shell "zsh"

Hide
Type "export POWERLEVEL9K_INSTANT_PROMPT=quiet && source ~/.zshrc 2>/dev/null"
Enter
Sleep 3s
# Seed zoxide and history
Type "zoxide add $HOME/repos/zshkit $HOME/.config/kitty $HOME/.config/zellij $HOME/repos/aidoc-cloud-infra"
Enter
Sleep 0.5s
Type "cd $HOME/repos/zshkit"
Enter
Sleep 0.3s
Type "cd $HOME/.config/kitty"
Enter
Sleep 0.3s
Type "cd $HOME/.config/zellij"
Enter
Sleep 0.3s
Type "cd $HOME"
Enter
Sleep 0.3s
Type "clear"
Enter
Sleep 0.5s
Show

# 1. Tab-complete a partial cd path
Type@160ms "cd ~/.con"
Sleep 0.5s
Tab
Sleep 1.2s
Tab
Sleep 1.2s
Enter
Sleep 1s
Type "pwd"
Enter
Sleep 0.8s

Type "cd ~"
Enter
Sleep 0.3s
Type "clear"
Enter
Sleep 0.3s

# 2. z — jump by keyword, no full path needed
Type@160ms "z zsh"
Enter
Sleep 0.8s
Type "pwd"
Enter
Sleep 0.8s

Type@160ms "z kitty"
Enter
Sleep 0.8s
Type "pwd"
Enter
Sleep 0.8s

# 3. cd - to go back to previous dir
Type@160ms "cd -"
Enter
Sleep 0.8s
Type "pwd"
Enter
Sleep 1.5s
