# AGENTS Instructions

Codex agents working in this repository should follow these guidelines:

- Code should be written in a clear, modular style with descriptive comments.
- Keep each Lua module self-contained and avoid global variables.
- When you modify code, run the check script to verify the repository state:

```bash
bash scripts/check.sh
```

The check script executes the Busted test suite if it is installed, or
prompts you to install it.
