if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fieval "$(uv generate-shell-completion bash)"
eval "$(uvx --generate-shell-completion bash)"
