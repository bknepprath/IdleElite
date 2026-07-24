$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$captureScript = Join-Path $projectRoot "scripts\capture-fighting-diamond-arena.ps1"
$captures = @(
    @{ Action = "fight-chickens"; Cue = "auto" },
    @{ Action = "fight-goblins"; Cue = "auto" },
    @{ Action = "fight-r.o.u.s.es"; Cue = "auto" },
    @{ Action = "fight-werewolves"; Cue = "werewolf-transform" },
    @{ Action = "fight-cave-trolls"; Cue = "auto" },
    @{ Action = "fight-vampires"; Cue = "auto" },
    @{ Action = "fight-dragons"; Cue = "auto" }
)

foreach ($capture in $captures) {
    & $captureScript -ActionId $capture.Action -FightLevel 99 -CaptureCue $capture.Cue -CaptureLabel "runtime-scale-final"
}
