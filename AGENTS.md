# Agent Instructions

## Godot Process Safety

This project uses Godot, and this machine can overheat if too many Godot instances run at once.

- Never call `Godot.exe` directly.
- Always launch Godot through `.\run-godot-safe.ps1`.
- Use headless Godot only.
- Do not launch the Godot editor UI or project manager.
- Do not use watch mode or long-running Godot processes.
- Across all agents combined, keep at most 4 Godot processes running at the same time.
- The wrapper waits up to 5 minutes for a slot. If no slot opens, continue with static analysis where possible and report that Godot validation is blocked.
- After every Godot command, verify no Godot process was left behind by that command. If a Godot process remains idle after the command should have completed, terminate it and report the PID.

Preferred validation:

```powershell
.\scripts\check-project.ps1
```

For one-off Godot commands, call the wrapper directly:

```powershell
.\run-godot-safe.ps1 --path . --quit-after 1
```
