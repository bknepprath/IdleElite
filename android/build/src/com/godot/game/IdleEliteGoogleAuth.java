/**************************************************************************/
/*  IdleEliteGoogleAuth.java                                               */
/**************************************************************************/

package com.godot.game;

import android.app.Activity;
import android.os.CancellationSignal;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.credentials.Credential;
import androidx.credentials.CredentialManager;
import androidx.credentials.CredentialManagerCallback;
import androidx.credentials.CustomCredential;
import androidx.credentials.GetCredentialRequest;
import androidx.credentials.GetCredentialResponse;
import androidx.credentials.exceptions.GetCredentialException;

import com.google.android.libraries.identity.googleid.GetGoogleIdOption;
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

public class IdleEliteGoogleAuth extends GodotPlugin {
	private static final String TAG = "IdleEliteGoogleAuth";
	private static final String PLUGIN_NAME = "IdleEliteGoogleAuth";
	private static final String SIGNAL_SIGN_IN_SUCCEEDED = "google_sign_in_succeeded";
	private static final String SIGNAL_SIGN_IN_FAILED = "google_sign_in_failed";

	private CredentialManager credentialManager;
	private String webClientId = "";
	private boolean signInInFlight = false;

	public IdleEliteGoogleAuth(Godot godot) {
		super(godot);
	}

	@NonNull
	@Override
	public String getPluginName() {
		return PLUGIN_NAME;
	}

	@NonNull
	@Override
	public Set<SignalInfo> getPluginSignals() {
		Set<SignalInfo> signals = new HashSet<>();
		signals.add(new SignalInfo(SIGNAL_SIGN_IN_SUCCEEDED, String.class, String.class, String.class));
		signals.add(new SignalInfo(SIGNAL_SIGN_IN_FAILED, String.class));
		return signals;
	}

	@UsedByGodot
	public int sign_in() {
		return sign_in_with_client_id(webClientId);
	}

	@UsedByGodot
	public int sign_in_with_client_id(String requestedWebClientId) {
		String trimmedClientId = requestedWebClientId == null ? "" : requestedWebClientId.trim();
		if (trimmedClientId.isEmpty()) {
			emitFailure("Google web client ID is not configured.");
			return 1;
		}

		if (signInInFlight) {
			emitFailure("Google sign-in is already in progress.");
			return 1;
		}

		Activity activity = getActivity();
		if (activity == null) {
			emitFailure("Google sign-in is unavailable until the activity is ready.");
			return 1;
		}

		webClientId = trimmedClientId;
		signInInFlight = true;
		activity.runOnUiThread(() -> startCredentialSignIn(activity, trimmedClientId));
		return 0;
	}

	private void startCredentialSignIn(Activity activity, String requestedWebClientId) {
		try {
			if (credentialManager == null) {
				credentialManager = CredentialManager.create(activity);
			}

			GetGoogleIdOption googleIdOption = new GetGoogleIdOption.Builder()
					.setFilterByAuthorizedAccounts(false)
					.setServerClientId(requestedWebClientId)
					.build();

			GetCredentialRequest request = new GetCredentialRequest.Builder()
					.addCredentialOption(googleIdOption)
					.build();

			credentialManager.getCredentialAsync(
					activity,
					request,
					new CancellationSignal(),
					ContextCompat.getMainExecutor(activity),
					new CredentialManagerCallback<GetCredentialResponse, GetCredentialException>() {
						@Override
						public void onResult(GetCredentialResponse result) {
							handleCredentialResponse(result);
						}

						@Override
						public void onError(@NonNull GetCredentialException exception) {
							completeFailure("Google sign-in failed: " + exception.getMessage());
						}
					}
			);
		} catch (Exception exception) {
			completeFailure("Google sign-in could not start: " + exception.getMessage());
		}
	}

	private void handleCredentialResponse(GetCredentialResponse result) {
		Credential credential = result.getCredential();
		if (!(credential instanceof CustomCredential)) {
			completeFailure("Google sign-in returned an unsupported credential.");
			return;
		}

		CustomCredential customCredential = (CustomCredential)credential;
		String credentialType = customCredential.getType();
		if (!GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL.equals(credentialType)
				&& !GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_SIWG_CREDENTIAL.equals(credentialType)) {
			completeFailure("Google sign-in returned an unsupported credential type.");
			return;
		}

		try {
			GoogleIdTokenCredential googleCredential = GoogleIdTokenCredential.createFrom(customCredential.getData());
			String idToken = nullToEmpty(googleCredential.getIdToken());
			if (idToken.isEmpty()) {
				completeFailure("Google sign-in did not return an ID token.");
				return;
			}

			String accountEmail = nullToEmpty(googleCredential.getId());
			String displayName = nullToEmpty(googleCredential.getDisplayName());
			signInInFlight = false;
			emitSignal(SIGNAL_SIGN_IN_SUCCEEDED, idToken, accountEmail, displayName);
		} catch (RuntimeException exception) {
			completeFailure("Google sign-in token could not be parsed: " + exception.getMessage());
		}
	}

	private void completeFailure(String message) {
		Log.w(TAG, message);
		signInInFlight = false;
		emitFailure(message);
	}

	private void emitFailure(String message) {
		emitSignal(SIGNAL_SIGN_IN_FAILED, nullToEmpty(message));
	}

	private String nullToEmpty(String value) {
		return value == null ? "" : value;
	}
}
