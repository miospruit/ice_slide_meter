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

[Setting name="Only Show On Ice"]
bool S_OnlyShowOnIce = false;

[Setting name="Invert Angle Sign"]
bool S_InvertAngleSign = false;

[Setting name="Angle Deadzone (deg)" min=0 max=8]
float S_AngleDeadzoneDeg = 0.6f;

[Setting name="HUD Meter Max Angle (deg)" min=10 max=90]
float S_HudMeterMaxAngleDeg = 45.0f;

[Setting name="HUD Good Angle (deg)" min=1 max=45]
float S_HudGoodAngleDeg = 12.0f;

[Setting name="HUD Warn Angle (deg)" min=1 max=60]
float S_HudWarnAngleDeg = 25.0f;

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
    const int HUD_METER_HALF_WIDTH = 12;

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
    int g_CachedLeftFill = -1;
    int g_CachedRightFill = -1;
    string g_CachedMeterBar = "";

    float Clamp(float v, float lo, float hi) {
        if (v < lo) return lo;
        if (v > hi) return hi;
        return v;
    }

    float Clamp01(float v) {
        return Clamp(v, 0.0f, 1.0f);
    }

    float Lerp(float a, float b, float t) {
        return a + (b - a) * t;
    }

    int ClampInt(int v, int lo, int hi) {
        if (v < lo) return lo;
        if (v > hi) return hi;
        return v;
    }

    float EffectiveAlpha(float baseAlpha, float dt) {
        const float a = Clamp01(baseAlpha);
        const float steps = Math::Max(1.0f, dt * 60.0f);
        return 1.0f - Math::Pow(1.0f - a, steps);
    }

    string BuildMeterBar(float angleDeg, float maxAbsDeg, int halfWidth) {
        const float safeMax = Math::Max(1.0f, maxAbsDeg);
        const float clampedAngle = Clamp(angleDeg, -safeMax, safeMax);
        const float norm = clampedAngle / safeMax;

        int leftFill = 0;
        int rightFill = 0;
        if (norm < 0.0f) {
            leftFill = int(Math::Round(Math::Abs(norm) * halfWidth));
        } else {
            rightFill = int(Math::Round(norm * halfWidth));
        }
        leftFill = ClampInt(leftFill, 0, halfWidth);
        rightFill = ClampInt(rightFill, 0, halfWidth);

        if (leftFill == g_CachedLeftFill && rightFill == g_CachedRightFill) {
            return g_CachedMeterBar;
        }

        string left = "";
        for (int i = 0; i < halfWidth; i++) {
            const bool isFill = i >= (halfWidth - leftFill);
            if (!isFill) {
                left += "-";
            } else if (i == (halfWidth - leftFill)) {
                left += "<";
            } else {
                left += "=";
            }
        }

        string right = "";
        for (int i = 0; i < halfWidth; i++) {
            const bool isFill = i < rightFill;
            if (!isFill) {
                right += "-";
            } else if (i == (rightFill - 1)) {
                right += ">";
            } else {
                right += "=";
            }
        }

        g_CachedLeftFill = leftFill;
        g_CachedRightFill = rightFill;
        g_CachedMeterBar = "[" + left + "|" + right + "]";
        return g_CachedMeterBar;
    }

    string Spaces(int count) {
        string out = "";
        for (int i = 0; i < count; i++) {
            out += " ";
        }
        return out;
    }

    string BuildMeterScaleLabel(float maxAbsDeg, int halfWidth) {
        const int safeHalfWidth = Math::Max(1, halfWidth);
        const float safeMax = Math::Max(1.0f, maxAbsDeg);
        const string leftLabel = "-" + Text::Format("%.0f", safeMax);
        const string centerLabel = "0";
        const string rightLabel = "+" + Text::Format("%.0f", safeMax);

        const int leftGap = Math::Max(1, safeHalfWidth - int(leftLabel.Length));
        const int rightGap = Math::Max(1, safeHalfWidth - int(rightLabel.Length));
        return leftLabel + Spaces(leftGap) + centerLabel + Spaces(rightGap) + rightLabel;
    }

    void HudTextLine(const string &in text) {
        if (g_State.isActive) {
            UI::Text(text);
        } else {
            UI::TextDisabled(text);
        }
    }

    void HudColoredLine(const string &in text, const vec4 &in color) {
        if (g_State.isActive) {
            UI::TextColored(color, text);
        } else {
            UI::TextDisabled(text);
        }
    }

    vec4 AngleColor(float angleDeg) {
        if (!g_State.isActive) return vec4(0.65f, 0.65f, 0.65f, 1.0f);
        const float goodThreshold = Clamp(S_HudGoodAngleDeg, 0.0f, S_HudWarnAngleDeg);
        const float warnThreshold = Math::Max(S_HudWarnAngleDeg, goodThreshold);
        const float absAngle = Math::Abs(angleDeg);
        if (absAngle <= goodThreshold) return vec4(0.35f, 0.95f, 0.45f, 1.0f);
        if (absAngle <= warnThreshold) return vec4(1.0f, 0.80f, 0.25f, 1.0f);
        return vec4(1.0f, 0.42f, 0.42f, 1.0f);
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
        if (!s.isDriving || s.isAirborne || !s.hasSignal || (S_OnlyShowOnIce && !s.isOnIce)) return 0.0f;
        const float speedFactor = Clamp01((s.speedKmh - S_MinSpeedKmh) / 80.0f);
        const float iceFactor = s.isOnIce ? 1.0f : 0.65f;
        const float jitter = Math::Abs(s.rawAngleDeg - s.smoothAngleDeg);
        const float jitterFactor = 1.0f - Clamp01(jitter / 25.0f);
        return Clamp01(speedFactor * iceFactor * jitterFactor);
    }

    float ApplyDeadzone(float angleDeg, float deadzoneDeg) {
        const float dz = Math::Max(0.0f, deadzoneDeg);
        if (Math::Abs(angleDeg) <= dz) return 0.0f;
        return angleDeg;
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
            float signedAngle = SignedAngleDeg(planarForward, planarVelDir, WORLD_UP);
            if (S_InvertAngleSign) signedAngle = -signedAngle;
            g_State.rawAngleDeg = ApplyDeadzone(signedAngle, S_AngleDeadzoneDeg);
            g_State.hasSignal = true;
        } else {
            g_State.rawAngleDeg = 0.0f;
        }

        const bool speedOk = g_State.speedKmh >= S_MinSpeedKmh;
        const bool surfaceOk = !S_OnlyShowOnIce || g_State.isOnIce;
        const bool stateOk = g_State.isDriving && !g_State.isAirborne && g_State.hasSignal && surfaceOk;
        g_State.isActive = stateOk && speedOk;

        if (!g_State.isDriving) {
            g_State.inactiveReason = "not driving";
        } else if (g_State.isAirborne) {
            g_State.inactiveReason = "airborne";
        } else if (!g_State.hasSignal) {
            g_State.inactiveReason = "low planar velocity";
        } else if (!surfaceOk) {
            g_State.inactiveReason = "not on ice";
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
        UI::SetNextWindowSize(int(340 * S_HudScale), int(160 * S_HudScale), UI::Cond::Always);

        int flags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoResize | UI::WindowFlags::NoMove;
        flags |= UI::WindowFlags::NoCollapse | UI::WindowFlags::NoSavedSettings;

        if (!UI::Begin("Ice Slide Assist", flags)) {
            UI::End();
            return;
        }

        HudTextLine("ICE");
        if (S_ShowNumericAngle) {
            HudColoredLine("Angle: " + Text::Format("%+.1f deg", g_State.smoothAngleDeg), AngleColor(g_State.smoothAngleDeg));
        }
        HudTextLine("Speed: " + Text::Format("%.1f km/h", g_State.speedKmh));
        HudTextLine("Slip: " + Text::Format("%.2f", g_State.smoothLateralSlip));
        HudTextLine("Confidence: " + Text::Format("%.2f", g_State.confidence));

        const float meterMaxAngleDeg = Math::Max(1.0f, S_HudMeterMaxAngleDeg);
        const string meterBar = BuildMeterBar(g_State.smoothAngleDeg, meterMaxAngleDeg, HUD_METER_HALF_WIDTH);
        const string meterScale = BuildMeterScaleLabel(meterMaxAngleDeg, HUD_METER_HALF_WIDTH);
        HudTextLine(" " + meterScale);
        HudTextLine(meterBar);

        if (g_State.isActive) {
            UI::Text("State: active");
        } else {
            UI::TextDisabled("State: inactive (" + g_State.inactiveReason + ")");
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
            UI::Text("Show On Ice: " + (S_OnlyShowOnIce ? "yes" : "no"));
            UI::Text("Invert Sign: " + (S_InvertAngleSign ? "yes" : "no"));
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
