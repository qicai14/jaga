#!/usr/bin/env bash
# PreToolUse guard for Bash: blocks destructive git and reads of .env. Exit 2 = block, stderr goes back to the agent.
input=$(cat)
cmd=$(printf '%s' "$input" | tr '\n' ' ' | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p')

block() { echo "Blocked by .claude/hooks/guard.sh: $1. Ask a human to do this." >&2; exit 2; }

case "$cmd" in
  *"git push"*"--force"*|*"git push"*" -f"*) block "force push" ;;
  *"git reset --hard"*) block "git reset --hard" ;;
  *"git clean -f"*|*"git clean -df"*|*"git clean -fd"*) block "git clean" ;;
  *"git branch -D"*) block "deleting a branch" ;;
  *"git checkout ."*|*"git restore ."*) block "discarding all changes" ;;
esac

# .env holds real keys. .env.example is fine.
if printf '%s' "$cmd" | grep -Eq '(^|[^A-Za-z0-9_.-])\.env($|[^.A-Za-z0-9_])'; then
  block "touching .env (use .env.example)"
fi
exit 0
