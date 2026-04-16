[Setting name="Enable HUD"]
bool S_EnableHud = true;

[Setting name="Show Numeric Angle"]
bool S_ShowNumericAngle = true;

[Setting name="Only Show While Driving"]
bool S_OnlyShowWhileDriving = true;

[Setting name="Minimum Speed (km/h)" min=0 max=500]
float S_MinSpeedKmh = 40.0f;

[Setting name="Smoothing (0-1)" min=0 max=1]
float S_SmoothingAlpha = 0.20f;

[Setting name="Reset Signal When Inactive"]
bool S_ResetWhenInactive = true;

[Setting name="HUD X" min=0 max=3840]
float S_HudX = 80.0f;

[Setting name="HUD Y" min=0 max=2160]
float S_HudY = 120.0f;

[Setting name="HUD Scale" min=0.5 max=3.0]
float S_HudScale = 1.0f;

[Setting name="Debug Mode"]
bool S_DebugMode = false;

bool g_MenuVisible = false;

namespace ISA {
    const vec3 WORLD_UP = vec3(0.0f, 1.0f, 0.0f);
    const float MIN_PLANAR_SPEED_MS = 0.5f;

    class SignalState {
        float speedKmh = 0.0f;
        float rawAngleDeg = 0.0f;
        float smoothAngleDeg = 0.0f;
        float lateralSlip = 0.0f;
        float smoothLateralSlip = 0.0f;
        float confidence = 0.0f;
        bool isDriving = false;
        bool isAirborne = false;
        bool isOnIce = false;
        bool isActive = false;
        bool hasSignal = false;
        string inactiveReason = "";
    }

    SignalState g_State;

    float Clamp01(float v) {
        if (v < 0.0f) return 0.0f;
        if (v > 1.0f) return 1.0f;
        return v;
    }

    float Lerp(float a, float b, float t) {
        return a + (b - a) * t;
    }

    float EffectiveAlpha(float baseAlpha, float dt) {
        const float a = Clamp01(baseAlpha);
        const float steps = Math::Max(1.0f, dt * 60.0f);
        return 1.0f - Math::Pow(1.0f - a, steps);
    }

    float LengthSq(const vec3 &in v) {
        return v.x * v.x + v.y * v.y + v.z * v.z;
    }

    vec3 SafeNormalize(const vec3 &in v) {
        const float lenSq = LengthSq(v);
        if (lenSq <= 1e-6f) return vec3();
        return v / Math::Sqrt(lenSq);
    }

    vec3 ProjectOnPlane(const vec3 &in v, const vec3 &in n) {
        return v - n * Math::Dot(v, n);
    }

    float SignedAngleDeg(const vec3 &in fromDir, const vec3 &in toDir, const vec3 &in planeNormal) {
        const float dot = Math::Dot(fromDir, toDir);
        const vec3 cross = Math::Cross(fromDir, toDir);
        const float signedCross = Math::Dot(planeNormal, cross);
        return Math::ToDeg(Math::Atan2(signedCross, dot));
    }

    bool IsIceMaterial(EPlugSurfaceMaterialId mat) {
        return mat == EPlugSurfaceMaterialId::Ice || mat == EPlugSurfaceMaterialId::RoadIce;
    }

    bool TryGetSignalInputs(CSceneVehicleVisState@ vis, vec3 &out planarForward, vec3 &out planarVelDir, float &out speedKmh, float &out lateralSlip, bool &out isOnIce) {
        if (vis is null) return false;

        const vec3 worldVel = vis.WorldVel;
        speedKmh = Math::Sqrt(LengthSq(worldVel)) * 3.6f;

        const vec3 forwardFlat = ProjectOnPlane(vis.Dir, WORLD_UP);
        const vec3 velFlat = ProjectOnPlane(worldVel, WORLD_UP);

        const float velFlatLen = Math::Sqrt(LengthSq(velFlat));
        if (velFlatLen < MIN_PLANAR_SPEED_MS) {
            planarForward = vec3();
            planarVelDir = vec3();
            lateralSlip = 0.0f;
            isOnIce = IsIceMaterial(vis.FLGroundContactMaterial) || IsIceMaterial(vis.FRGroundContactMaterial) || IsIceMaterial(vis.RLGroundContactMaterial) || IsIceMaterial(vis.RRGroundContactMaterial);
            return false;
        }

        planarForward = SafeNormalize(forwardFlat);
        planarVelDir = velFlat / velFlatLen;

        const vec3 rightDir = SafeNormalize(-vis.Left);
        lateralSlip = Math::Dot(worldVel, rightDir);

        isOnIce = IsIceMaterial(vis.FLGroundContactMaterial) || IsIceMaterial(vis.FRGroundContactMaterial) || IsIceMaterial(vis.RLGroundContactMaterial) || IsIceMaterial(vis.RRGroundContactMaterial);
        return LengthSq(planarForward) > 0.0f && LengthSq(planarVelDir) > 0.0f;
    }

    float ComputeConfidence(const SignalState &in s) {
        if (!s.isDriving || s.isAirborne || !s.hasSignal) return 0.0f;
        const float speedFactor = Clamp01((s.speedKmh - S_MinSpeedKmh) / 80.0f);
        const float iceFactor = s.isOnIce ? 1.0f : 0.65f;
        return Clamp01(speedFactor * iceFactor);
    }

    void Tick(float dt) {
        dt = Math::Max(0.0f, dt);

        auto app = cast<CTrackMania>(GetApp());
        auto vis = VehicleState::ViewingPlayerState();
        auto viewingPlayer = cast<CSmPlayer>(VehicleState::GetViewingPlayer());

        const bool hasPlayground = app !is null && app.CurrentPlayground !is null;
        g_State.isDriving = hasPlayground && vis !is null && viewingPlayer !is null;
        if (!S_OnlyShowWhileDriving) {
            g_State.isDriving = vis !is null;
        }

        g_State.isAirborne = vis is null ? true : !vis.IsGroundContact;
        g_State.isOnIce = false;
        g_State.hasSignal = false;
        g_State.inactiveReason = "";

        vec3 planarForward;
        vec3 planarVelDir;
        float speedKmh = 0.0f;
        float lateralSlip = 0.0f;
        bool isOnIce = false;

        const bool hasInputs = TryGetSignalInputs(vis, planarForward, planarVelDir, speedKmh, lateralSlip, isOnIce);
        g_State.speedKmh = speedKmh;
        g_State.lateralSlip = lateralSlip;
        g_State.isOnIce = isOnIce;

        if (hasInputs) {
            g_State.rawAngleDeg = SignedAngleDeg(planarForward, planarVelDir, WORLD_UP);
            g_State.hasSignal = true;
        } else {
            g_State.rawAngleDeg = 0.0f;
        }

        const bool speedOk = g_State.speedKmh >= S_MinSpeedKmh;
        const bool stateOk = g_State.isDriving && !g_State.isAirborne && g_State.hasSignal;
        g_State.isActive = stateOk && speedOk;

        if (!g_State.isDriving) {
            g_State.inactiveReason = "not driving";
        } else if (g_State.isAirborne) {
            g_State.inactiveReason = "airborne";
        } else if (!g_State.hasSignal) {
            g_State.inactiveReason = "low planar velocity";
        } else if (!speedOk) {
            g_State.inactiveReason = "below min speed";
        }

        g_State.confidence = ComputeConfidence(g_State);

        const float alpha = EffectiveAlpha(S_SmoothingAlpha, dt);
        if (g_State.isActive) {
            g_State.smoothAngleDeg = Lerp(g_State.smoothAngleDeg, g_State.rawAngleDeg, alpha);
            g_State.smoothLateralSlip = Lerp(g_State.smoothLateralSlip, g_State.lateralSlip, alpha);
        } else if (S_ResetWhenInactive) {
            const float resetAlpha = EffectiveAlpha(0.10f, dt);
            g_State.smoothAngleDeg = Lerp(g_State.smoothAngleDeg, 0.0f, resetAlpha);
            g_State.smoothLateralSlip = Lerp(g_State.smoothLateralSlip, 0.0f, resetAlpha);
        }
    }

    void RenderHud() {
        if (!S_EnableHud) return;

        UI::SetNextWindowPos(int(S_HudX), int(S_HudY), UI::Cond::Always);
        UI::SetNextWindowSize(int(260 * S_HudScale), int(130 * S_HudScale), UI::Cond::Always);

        int flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoResize | UI::WindowFlags::NoMove;
        flags |= UI::WindowFlags::NoCollapse | UI::WindowFlags::NoSavedSettings;

        if (!UI::Begin("Ice Slide Assist", flags)) {
            UI::End();
            return;
        }

        UI::Text("ICE");
        if (S_ShowNumericAngle) {
            UI::Text("Angle: " + Text::Format("%+.1f deg", g_State.smoothAngleDeg));
        }
        UI::Text("Speed: " + Text::Format("%.1f km/h", g_State.speedKmh));
        UI::Text("Slip: " + Text::Format("%.2f", g_State.smoothLateralSlip));
        UI::Text("Confidence: " + Text::Format("%.2f", g_State.confidence));
        if (g_State.isActive) {
            UI::Text("Active");
        } else {
            UI::Text("Inactive: " + g_State.inactiveReason);
        }

        UI::End();
    }

    void RenderDebugWindow() {
        if (!S_DebugMode) return;

        if (UI::Begin("Ice Slide Debug", S_DebugMode)) {
            UI::Text("Phase 1 telemetry active");
            UI::Separator();
            UI::Text("Driving: " + (g_State.isDriving ? "yes" : "no"));
            UI::Text("Airborne: " + (g_State.isAirborne ? "yes" : "no"));
            UI::Text("On Ice: " + (g_State.isOnIce ? "yes" : "no"));
            UI::Text("Has Signal: " + (g_State.hasSignal ? "yes" : "no"));
            UI::Text("Inactive reason: " + g_State.inactiveReason);
            UI::Text("Raw angle: " + Text::Format("%+.2f", g_State.rawAngleDeg));
            UI::Text("Smoothed angle: " + Text::Format("%+.2f", g_State.smoothAngleDeg));
            UI::Text("Lateral slip: " + Text::Format("%.3f", g_State.lateralSlip));
            UI::Text("Smoothed slip: " + Text::Format("%.3f", g_State.smoothLateralSlip));
        }
        UI::End();
    }
}

void Main() {
}

void Update(float dt) {
    ISA::Tick(dt);
}

void Render() {
    ISA::RenderHud();
}

void RenderInterface() {
    ISA::RenderDebugWindow();
}

void RenderMenu() {
    if (UI::MenuItem("Ice Slide Assist", "", g_MenuVisible)) {
        g_MenuVisible = !g_MenuVisible;
    }
}
