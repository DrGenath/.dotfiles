if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
fieval "$(uv generate-shell-completion bash)"
eval "$(uvx --generate-shell-completion bash)"
