package com.godot.game;

import android.app.Activity;
import androidx.annotation.NonNull;
import com.google.android.ump.ConsentInformation;
import com.google.android.ump.ConsentRequestParameters;
import com.google.android.ump.FormError;
import com.google.android.ump.UserMessagingPlatform;
import java.util.Collections;
import java.util.Set;
import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

/** UMP owns consent persistence and regional eligibility. Never infer consent locally. */
public final class IdleEliteConsent extends GodotPlugin {
    private boolean busy;
    private ConsentInformation information;

    public IdleEliteConsent(Godot godot) { super(godot); }

    @NonNull @Override public String getPluginName() { return "IdleEliteConsent"; }

    @NonNull @Override public Set<SignalInfo> getPluginSignals() {
        return Collections.singleton(new SignalInfo("consent_finished", Boolean.class, Boolean.class, String.class));
    }

    private void finish(FormError error) {
        busy = false;
        emitSignal("consent_finished", information != null && information.canRequestAds(),
            information != null && information.getPrivacyOptionsRequirementStatus()
                == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED,
            error == null ? "" : error.getMessage());
    }

    @UsedByGodot public void request_consent() {
        Activity activity = getActivity();
        if (activity == null) {
            emitSignal("consent_finished", false, false, "Activity unavailable");
            return;
        }
        activity.runOnUiThread(() -> {
            if (busy) return;
            busy = true;
            information = UserMessagingPlatform.getConsentInformation(activity);
            information.requestConsentInfoUpdate(activity, new ConsentRequestParameters.Builder().build(),
                () -> UserMessagingPlatform.loadAndShowConsentFormIfRequired(activity, this::finish),
                this::finish);
        });
    }

    @UsedByGodot public void show_privacy_options() {
        Activity activity = getActivity();
        if (activity == null) {
            emitSignal("consent_finished", false, false, "Activity unavailable");
            return;
        }
        activity.runOnUiThread(() -> {
            if (busy) return;
            busy = true;
            information = UserMessagingPlatform.getConsentInformation(activity);
            UserMessagingPlatform.showPrivacyOptionsForm(activity, this::finish);
        });
    }
}
