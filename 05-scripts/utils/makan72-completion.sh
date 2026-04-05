#!/usr/bin/env bash
# makan72-completion.sh — Auto-completion para Bash
# Uso: source ~/.Makan72/05-scripts/utils/makan72-completion.sh

_makan72_completion() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Comandos principais
    local commands="project agent start stop status health bot gate shield info layout launch broadcast attach version slot commit peek checkpoint verify audit dashboard help"
    local project_cmds="create register list switch info remove active"
    local agent_cmds="list add remove pause activate info stop sessions attach cleanup complete-introspect"
    
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$commands" -- "$cur"))
    elif [[ ${COMP_WORDS[1]} == "project" && ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$project_cmds" -- "$cur"))
    elif [[ ${COMP_WORDS[1]} == "agent" && ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=($(compgen -W "$agent_cmds" -- "$cur"))
    elif [[ ${COMP_WORDS[1]} == "health" && ${COMP_CWORD} -eq 2 ]]; then
        COMPREPLY=($(compgen -W "quick full" -- "$cur"))
    elif [[ ${COMP_WORDS[1]} == "status" ]]; then
        COMPREPLY=()
    fi
}

complete -F _makan72_completion makan72
