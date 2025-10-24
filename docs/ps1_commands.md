Dauerhafte Scriptausführung erlauben
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
Temporäre Scriptausführung erlauben
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

VSCode Extensions exportieren
code --list-extensions > extensions.txt
VSCode Extensions installieren
Get-Content extensions.txt | ForEach-Object { code --install-extension $_ }
