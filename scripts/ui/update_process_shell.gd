extends RefCounted


static func process_background_maintenance(host, delta: float) -> void:
	host.background_maintenance_elapsed += maxf(0.0, delta)
	if host.background_maintenance_pending_delta <= 0.0:
		if host.background_maintenance_elapsed < host.BACKGROUND_MAINTENANCE_INTERVAL_SECONDS:
			return
		host.background_maintenance_pending_delta = host.background_maintenance_elapsed
		host.background_maintenance_elapsed = 0.0
		host.background_maintenance_step_index = 0
	var step_index: int = host.background_maintenance_step_index % host.BACKGROUND_MAINTENANCE_STEP_COUNT
	process_background_maintenance_step(host, step_index, host.background_maintenance_pending_delta)
	host.background_maintenance_step_index = step_index + 1
	if host.background_maintenance_step_index >= host.BACKGROUND_MAINTENANCE_STEP_COUNT:
		host.background_maintenance_step_index = 0
		host.background_maintenance_pending_delta = 0.0


static func process_background_maintenance_step(host, step_index: int, maintenance_delta: float) -> void:
	match step_index:
		0:
			host._crash_report_runtime().process_session_heartbeat(maintenance_delta)
		1:
			host._ad_bonus_runtime().process(maintenance_delta)
		2:
			host._passive_modules_runtime().process_passive_modules(host._unix_now())
		3:
			host._convergence_runtime()._process_convergence_modules()
		4:
			host._hub_surface()._process_hub_modules(maintenance_delta)
		5:
			host._thieving_surface()._process_thieving_action_jails()
		6:
			host._online_runtime().process(maintenance_delta)
