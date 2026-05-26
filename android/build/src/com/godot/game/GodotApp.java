/**************************************************************************/
/*  GodotApp.java                                                         */
/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to  */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/

package com.godot.game;

import org.godotengine.godot.Godot;
import org.godotengine.godot.GodotActivity;

import android.os.Bundle;
import android.os.Build;
import android.os.PowerManager;
import android.util.Log;

import androidx.activity.EdgeToEdge;
import androidx.core.splashscreen.SplashScreen;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

/**
 * Template activity for Godot Android builds.
 * Feel free to extend and modify this class for your custom logic.
 */
public class GodotApp extends GodotActivity {
	private static final String TAG = "IdleEliteCrash";
	private static final String PENDING_CRASH_REPORT_FILE = "pending-crash-report.json";
	private static final int MAX_DIAGNOSTIC_EVENTS = 80;
	private Thread.UncaughtExceptionHandler previousExceptionHandler;
	private PowerManager.OnThermalStatusChangedListener thermalStatusListener;
	private final List<String> diagnosticEvents = new ArrayList<>();

	static {
		// .NET libraries.
		if (BuildConfig.FLAVOR.equals("mono")) {
			try {
				Log.v("GODOT", "Loading System.Security.Cryptography.Native.Android library");
				System.loadLibrary("System.Security.Cryptography.Native.Android");
			} catch (UnsatisfiedLinkError e) {
				Log.e("GODOT", "Unable to load System.Security.Cryptography.Native.Android library");
			}
		}
	}

	private final Runnable updateWindowAppearance = () -> {
		Godot godot = getGodot();
		if (godot != null) {
			godot.enableImmersiveMode(godot.isInImmersiveMode(), true);
			godot.enableEdgeToEdge(godot.isInEdgeToEdgeMode(), true);
			godot.setSystemBarsAppearance();
		}
	};

	@Override
	public void onCreate(Bundle savedInstanceState) {
		installCrashReporter();
		writeDiagnosticEvent("create");
		cleanupLegacyExternalCrashReports();
		SplashScreen.installSplashScreen(this);
		EdgeToEdge.enable(this);
		super.onCreate(savedInstanceState);
		installThermalStatusLogger();
	}

	@Override
	public void onResume() {
		super.onResume();
		writeDiagnosticEvent("resume");
		updateWindowAppearance.run();
	}

	@Override
	protected void onPause() {
		writeDiagnosticEvent("pause");
		super.onPause();
	}

	@Override
	protected void onStop() {
		writeDiagnosticEvent("stop");
		super.onStop();
	}

	@Override
	public void onTrimMemory(int level) {
		writeDiagnosticEvent("trim_memory:" + level);
		super.onTrimMemory(level);
	}

	@Override
	public void onLowMemory() {
		writeDiagnosticEvent("low_memory");
		super.onLowMemory();
	}

	@Override
	public void onGodotMainLoopStarted() {
		super.onGodotMainLoopStarted();
		writeDiagnosticEvent("godot_main_loop_started");
		runOnUiThread(updateWindowAppearance);
	}

	private void installThermalStatusLogger() {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q || thermalStatusListener != null) {
			return;
		}

		PowerManager powerManager = (PowerManager)getSystemService(POWER_SERVICE);
		if (powerManager == null) {
			return;
		}

		writeDiagnosticEvent("thermal_status:" + thermalStatusName(powerManager.getCurrentThermalStatus()));
		thermalStatusListener = status -> writeDiagnosticEvent("thermal_status:" + thermalStatusName(status));
		powerManager.addThermalStatusListener(getMainExecutor(), thermalStatusListener);
	}

	private void installCrashReporter() {
		if (previousExceptionHandler != null) {
			return;
		}

		previousExceptionHandler = Thread.getDefaultUncaughtExceptionHandler();
		Thread.setDefaultUncaughtExceptionHandler((thread, throwable) -> {
			try {
				writeCrashReport(thread, throwable);
			} catch (Throwable reporterError) {
				Log.e(TAG, "Unable to write crash report", reporterError);
			}

			if (previousExceptionHandler != null) {
				previousExceptionHandler.uncaughtException(thread, throwable);
			}
		});
	}

	private void writeCrashReport(Thread thread, Throwable throwable) {
		File report = getPendingCrashReportFile();
		if (report == null) {
			return;
		}

		try (FileWriter writer = new FileWriter(report, false)) {
			writer.write("{\n");
			writer.write("  \"timestamp\": \"" + escapeJson(wallClockTimestamp()) + "\",\n");
			writer.write("  \"package\": \"" + escapeJson(getPackageName()) + "\",\n");
			writer.write("  \"version_name\": \"" + escapeJson(BuildConfig.VERSION_NAME) + "\",\n");
			writer.write("  \"version_code\": " + BuildConfig.VERSION_CODE + ",\n");
			writer.write("  \"thread\": \"" + escapeJson(thread != null ? thread.getName() : "unknown") + "\",\n");
			writer.write("  \"device\": \"" + escapeJson(Build.MANUFACTURER + " " + Build.MODEL) + "\",\n");
			writer.write("  \"android_sdk\": " + Build.VERSION.SDK_INT + ",\n");
			writer.write("  \"exception\": \"" + escapeJson(throwable != null ? throwable.toString() : "unknown") + "\",\n");
			writer.write("  \"stack_trace\": \"" + escapeJson(stackTrace(throwable)) + "\",\n");
			writer.write("  \"diagnostic_events\": [\n");
			List<String> eventsSnapshot = diagnosticEventsSnapshot();
			for (int i = 0; i < eventsSnapshot.size(); i++) {
				writer.write("    \"" + escapeJson(eventsSnapshot.get(i)) + "\"");
				writer.write(i == eventsSnapshot.size() - 1 ? "\n" : ",\n");
			}
			writer.write("  ]\n");
			writer.write("}\n");
			Log.e(TAG, "Wrote crash report: " + report.getAbsolutePath());
		} catch (IOException exception) {
			Log.e(TAG, "Unable to write crash report", exception);
		}
	}

	private void writeDiagnosticEvent(String event) {
		String line = wallClockTimestamp() + " " + event + " version=" + BuildConfig.VERSION_NAME + "(" + BuildConfig.VERSION_CODE + ") device=" + Build.MANUFACTURER + " " + Build.MODEL;
		synchronized (diagnosticEvents) {
			diagnosticEvents.add(line);
			while (diagnosticEvents.size() > MAX_DIAGNOSTIC_EVENTS) {
				diagnosticEvents.remove(0);
			}
		}
		Log.i(TAG, line);
	}

	private File getPendingCrashReportFile() {
		File internalRoot = getFilesDir();
		if (internalRoot == null) {
			return null;
		}
		return new File(internalRoot, PENDING_CRASH_REPORT_FILE);
	}

	private void cleanupLegacyExternalCrashReports() {
		File legacyDir = getExternalFilesDir("crash-reports");
		if (legacyDir != null && legacyDir.exists() && !deleteRecursively(legacyDir)) {
			Log.w(TAG, "Unable to clear legacy external crash report directory: " + legacyDir.getAbsolutePath());
		}
	}

	private boolean deleteRecursively(File file) {
		if (file == null || !file.exists()) {
			return true;
		}
		if (file.isDirectory()) {
			File[] children = file.listFiles();
			if (children != null) {
				for (File child : children) {
					if (!deleteRecursively(child)) {
						return false;
					}
				}
			}
		}
		return file.delete();
	}

	private List<String> diagnosticEventsSnapshot() {
		synchronized (diagnosticEvents) {
			return new ArrayList<>(diagnosticEvents);
		}
	}

	private String stackTrace(Throwable throwable) {
		if (throwable == null) {
			return "";
		}
		StringWriter buffer = new StringWriter();
		PrintWriter writer = new PrintWriter(buffer);
		throwable.printStackTrace(writer);
		writer.flush();
		return buffer.toString();
	}

	private String wallClockTimestamp() {
		return new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSZ", Locale.US).format(new Date());
	}

	private String thermalStatusName(int status) {
		switch (status) {
			case PowerManager.THERMAL_STATUS_NONE:
				return "none";
			case PowerManager.THERMAL_STATUS_LIGHT:
				return "light";
			case PowerManager.THERMAL_STATUS_MODERATE:
				return "moderate";
			case PowerManager.THERMAL_STATUS_SEVERE:
				return "severe";
			case PowerManager.THERMAL_STATUS_CRITICAL:
				return "critical";
			case PowerManager.THERMAL_STATUS_EMERGENCY:
				return "emergency";
			case PowerManager.THERMAL_STATUS_SHUTDOWN:
				return "shutdown";
			default:
				return "unknown:" + status;
		}
	}

	private String escapeJson(String value) {
		if (value == null) {
			return "";
		}
		StringBuilder out = new StringBuilder(value.length() + 16);
		for (int i = 0; i < value.length(); i++) {
			char c = value.charAt(i);
			switch (c) {
				case '\\':
					out.append("\\\\");
					break;
				case '"':
					out.append("\\\"");
					break;
				case '\n':
					out.append("\\n");
					break;
				case '\r':
					out.append("\\r");
					break;
				case '\t':
					out.append("\\t");
					break;
				default:
					if (c < 0x20) {
						out.append(String.format(Locale.US, "\\u%04x", (int)c));
					} else {
						out.append(c);
					}
					break;
			}
		}
		return out.toString();
	}
}
