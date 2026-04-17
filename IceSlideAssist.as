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

[Setting name="Enable Offline Self-Tests"]
bool S_EnableOfflineSelfTests = true;

[Setting name="Enable Ghost Replay Test Mode"]
bool S_EnableGhostReplay = false;

[Setting name="Ghost Files Directory"]
string S_GhostDirectory = "ghosts";

[Setting name="Selected Ghost File"]
string S_GhostSelectedFile = "";

[Setting name="Ghost Playback Speed" min=0.1 max=4.0]
float S_GhostPlaybackSpeed = 1.0f;

[Setting name="Ghost Replay Loop"]
bool S_GhostReplayLoop = true;

[Setting name="Enable V2 Ice Slide Gauge"]
bool S_EnableV2Gauge = true;

[Setting name="V2 Target Angle Min (deg)" min=0 max=60]
float S_V2TargetAngleMinDeg = 15.0f;

[Setting name="V2 Target Angle Max (deg)" min=0 max=60]
float S_V2TargetAngleMaxDeg = 30.0f;

[Setting name="V2 Under-Slide Angle (deg)" min=0 max=40]
float S_V2UnderSlideAngleDeg = 10.0f;

[Setting name="V2 Over-Slide Angle (deg)" min=10 max=70]
float S_V2OverSlideAngleDeg = 40.0f;

[Setting name="V2 Max Speed Loss (km/h/s)" min=1 max=80]
float S_V2MaxSpeedLossKmhPerSec = 22.0f;

[Setting name="V2 Max Angle Oscillation (deg/s)" min=10 max=360]
float S_V2MaxOscillationDegPerSec = 140.0f;

bool g_MenuVisible = false;

namespace ISA {
    const vec3 WORLD_UP = vec3(0.0f, 1.0f, 0.0f);
    const float MIN_PLANAR_SPEED_MS = 0.5f;
    const int HUD_METER_HALF_WIDTH = 12;

    class SignalState {
        float speedKmh = 0.0f;
        float speedDeltaKmhPerSec = 0.0f;
        float smoothSpeedDeltaKmhPerSec = 0.0f;
        float rawAngleDeg = 0.0f;
        float smoothAngleDeg = 0.0f;
        float lateralSlip = 0.0f;
        float smoothLateralSlip = 0.0f;
        float angleOscillationDegPerSec = 0.0f;
        float confidence = 0.0f;
        float angleScore = 0.0f;
        float speedScore = 0.0f;
        float stabilityScore = 0.0f;
        float efficiencyScore = 0.0f;
        string slideState = "Grip";
        bool isDriving = false;
        bool isAirborne = false;
        bool isOnIce = false;
        bool isActive = false;
        bool hasSignal = false;
        string inactiveReason = "";
    }

    class CoreConfig {
        float minSpeedKmh = 40.0f;
        bool onlyShowOnIce = false;
        float smoothingAlpha = 0.20f;
        bool resetWhenInactive = true;
    }

    class FrameInputs {
        float dt = 0.0f;
        float speedKmh = 0.0f;
        float prevSpeedKmh = 0.0f;
        float rawAngleDeg = 0.0f;
        float prevRawAngleDeg = 0.0f;
        float lateralSlip = 0.0f;
        float prevSmoothAngleDeg = 0.0f;
        float prevSmoothLateralSlip = 0.0f;
        float prevSmoothSpeedDeltaKmhPerSec = 0.0f;
        bool isDriving = false;
        bool isAirborne = true;
        bool isOnIce = false;
        bool hasSignal = false;
    }

    class FrameOutput {
        float smoothAngleDeg = 0.0f;
        float smoothLateralSlip = 0.0f;
        float speedDeltaKmhPerSec = 0.0f;
        float smoothSpeedDeltaKmhPerSec = 0.0f;
        float angleOscillationDegPerSec = 0.0f;
        float confidence = 0.0f;
        float angleScore = 0.0f;
        float speedScore = 0.0f;
        float stabilityScore = 0.0f;
        float efficiencyScore = 0.0f;
        string slideState = "Grip";
        bool isActive = false;
        string inactiveReason = "";
    }

    class GhostFrame {
        float speedKmh = 0.0f;
        float rawAngleDeg = 0.0f;
        float lateralSlip = 0.0f;
        bool isDriving = true;
        bool isAirborne = false;
        bool isOnIce = true;
        bool hasSignal = true;
    }

    SignalState g_State;
    int g_CachedLeftFill = -1;
    int g_CachedRightFill = -1;
    string g_CachedMeterBar = "";
    bool g_SelfTestsPassed = false;
    string g_SelfTestReport = "Not run";
    array<GhostFrame@> g_GhostFrames;
    array<string> g_GhostFiles;
    int g_SelectedGhostOption = 0;
    string g_GhostLoadedPath = "";
    string g_GhostStatus = "Ghost replay idle";
    bool g_GhostReady = false;
    uint g_GhostFrameIndex = 0;
    float g_GhostFrameAccumulator = 0.0f;
    bool g_ShowGhostPickerOnStartup = true;

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

    CoreConfig BuildCoreConfig() {
        CoreConfig c;
        c.minSpeedKmh = S_MinSpeedKmh;
        c.onlyShowOnIce = S_OnlyShowOnIce;
        c.smoothingAlpha = S_SmoothingAlpha;
        c.resetWhenInactive = S_ResetWhenInactive;
        return c;
    }

    float ScoreAngleBand(float absAngleDeg) {
        const float under = Math::Max(0.1f, S_V2UnderSlideAngleDeg);
        const float targetMin = Math::Max(under, S_V2TargetAngleMinDeg);
        const float targetMax = Math::Max(targetMin, S_V2TargetAngleMaxDeg);
        const float over = Math::Max(targetMax + 0.1f, S_V2OverSlideAngleDeg);

        if (absAngleDeg <= under) {
            return 0.35f * Clamp01(absAngleDeg / under);
        }
        if (absAngleDeg < targetMin) {
            return Lerp(0.35f, 1.0f, Clamp01((absAngleDeg - under) / Math::Max(0.1f, targetMin - under)));
        }
        if (absAngleDeg <= targetMax) {
            return 1.0f;
        }
        if (absAngleDeg < over) {
            return Clamp01(1.0f - (absAngleDeg - targetMax) / Math::Max(0.1f, over - targetMax));
        }
        return 0.0f;
    }

    float ScoreSpeedEfficiency(float speedDeltaKmhPerSec) {
        if (speedDeltaKmhPerSec >= 0.0f) return 1.0f;
        const float maxLoss = Math::Max(1.0f, S_V2MaxSpeedLossKmhPerSec);
        return Clamp01(1.0f - Math::Abs(speedDeltaKmhPerSec) / maxLoss);
    }

    float ScoreStability(float angleOscillationDegPerSec) {
        const float maxOsc = Math::Max(10.0f, S_V2MaxOscillationDegPerSec);
        return Clamp01(1.0f - angleOscillationDegPerSec / maxOsc);
    }

    string ClassifySlideState(bool isActive, float smoothAngleDeg, float prevSmoothAngleDeg, float speedDeltaKmhPerSec, float angleScore, float speedScore, float stabilityScore) {
        if (!isActive) return "Inactive";

        const float absAngle = Math::Abs(smoothAngleDeg);
        const float prevAbsAngle = Math::Abs(prevSmoothAngleDeg);
        const float targetMin = Math::Max(0.0f, S_V2TargetAngleMinDeg);
        const float targetMax = Math::Max(targetMin, S_V2TargetAngleMaxDeg);
        const float under = Math::Max(0.0f, S_V2UnderSlideAngleDeg);
        const float over = Math::Max(targetMax, S_V2OverSlideAngleDeg);

        if (stabilityScore < 0.30f) return "Unstable";
        if (absAngle > over && speedDeltaKmhPerSec < -6.0f) return "OverSlide";
        if (absAngle < under) {
            if (absAngle > prevAbsAngle + 0.3f) return "Entry";
            return "UnderSlide";
        }
        if (prevAbsAngle > targetMin && absAngle < targetMin && absAngle < prevAbsAngle) return "Exit";
        if (absAngle >= targetMin && absAngle <= targetMax && angleScore > 0.8f && speedScore > 0.45f && stabilityScore > 0.45f) {
            return "SlideGood";
        }
        return "Slide";
    }

    vec4 SlideStateColor(const string &in slideState) {
        if (slideState == "SlideGood") return vec4(0.35f, 0.95f, 0.45f, 1.0f);
        if (slideState == "Entry" || slideState == "Exit" || slideState == "Slide") return vec4(0.40f, 0.85f, 1.0f, 1.0f);
        if (slideState == "UnderSlide") return vec4(1.0f, 0.80f, 0.25f, 1.0f);
        if (slideState == "OverSlide" || slideState == "Unstable") return vec4(1.0f, 0.42f, 0.42f, 1.0f);
        return vec4(0.65f, 0.65f, 0.65f, 1.0f);
    }

    vec4 ScoreColor(float score) {
        const float t = Clamp01(score);
        return vec4(
            Lerp(1.0f, 0.35f, t),
            Lerp(0.35f, 0.95f, t),
            0.35f,
            1.0f
        );
    }

    int NextGhostByte(const string &in raw, int &inout cursor) {
        const int len = int(raw.Length);
        if (len <= 0) return 0;
        const int idx = (cursor % len + len) % len;
        cursor = (idx + 1) % len;
        return int(raw[idx]);
    }

    bool HasGhostSuffix(const string &in path) {
        const string suffix = ".ghost.gbx";
        const string lower = path.ToLower();
        if (lower.Length < suffix.Length) return false;
        return lower.SubStr(lower.Length - suffix.Length) == suffix;
    }

    string FileNameFromPath(const string &in path) {
        int slash = -1;
        for (uint i = 0; i < path.Length; i++) {
            const int ch = path[i];
            if (ch == 47 || ch == 92) {
                slash = int(i);
            }
        }
        if (slash < 0) return path;
        return path.SubStr(slash + 1);
    }

    bool StringInArray(const array<string> &in items, const string &in value) {
        for (uint i = 0; i < items.Length; i++) {
            if (items[i] == value) return true;
        }
        return false;
    }

    string ResolveGhostDirectoryPath() {
        if (S_GhostDirectory.Length == 0) {
            S_GhostDirectory = "ghosts";
        }

        if (IO::FolderExists(S_GhostDirectory)) {
            return S_GhostDirectory;
        }

        const string storageDir = IO::FromStorageFolder(S_GhostDirectory);
        if (IO::FolderExists(storageDir)) {
            return storageDir;
        }

        return S_GhostDirectory;
    }

    void RefreshGhostFileOptions() {
        g_GhostFiles.RemoveRange(0, g_GhostFiles.Length);
        const string ghostDir = ResolveGhostDirectoryPath();

        if (!IO::FolderExists(ghostDir)) {
            g_GhostStatus = "Ghost directory missing: " + ghostDir;
            return;
        }

        array<string> entries = IO::IndexFolder(ghostDir, false);
        for (uint i = 0; i < entries.Length; i++) {
            const string path = entries[i];
            if (!HasGhostSuffix(path)) continue;
            g_GhostFiles.InsertLast(FileNameFromPath(path));
        }

        g_GhostFiles.SortAsc();

        if (g_GhostFiles.Length == 0) {
            g_GhostStatus = "No .Ghost.gbx files found in " + ghostDir;
            S_GhostSelectedFile = "";
            g_SelectedGhostOption = 0;
            return;
        }

        if (S_GhostSelectedFile.Length == 0 || !StringInArray(g_GhostFiles, S_GhostSelectedFile)) {
            S_GhostSelectedFile = g_GhostFiles[0];
        }

        g_SelectedGhostOption = 0;
        for (uint i = 0; i < g_GhostFiles.Length; i++) {
            if (g_GhostFiles[i] == S_GhostSelectedFile) {
                g_SelectedGhostOption = int(i);
                break;
            }
        }
    }

    string ResolveGhostPath() {
        if (S_GhostSelectedFile.Length == 0) {
            return "";
        }

        const string ghostDir = ResolveGhostDirectoryPath();
        const bool hasSlash = ghostDir.Length > 0 && (ghostDir[ghostDir.Length - 1] == 47 || ghostDir[ghostDir.Length - 1] == 92);
        const string joined = hasSlash ? ghostDir + S_GhostSelectedFile : ghostDir + "/" + S_GhostSelectedFile;

        if (IO::FileExists(joined)) return joined;

        const string storageCandidate = IO::FromStorageFolder(joined);
        if (IO::FileExists(storageCandidate)) return storageCandidate;
        return joined;
    }

    void ResetGhostPlaybackCursor() {
        g_GhostFrameIndex = 0;
        g_GhostFrameAccumulator = 0.0f;
    }

    bool LoadGhostReplayData(bool forceReload = false) {
        if (forceReload || g_GhostFiles.Length == 0) {
            RefreshGhostFileOptions();
        }

        const string resolvedPath = ResolveGhostPath();
        if (resolvedPath.Length == 0) {
            g_GhostFrames.RemoveRange(0, g_GhostFrames.Length);
            g_GhostLoadedPath = "";
            g_GhostReady = false;
            g_GhostStatus = "No ghost selected";
            return false;
        }

        if (!forceReload && g_GhostReady && g_GhostLoadedPath == resolvedPath) {
            return true;
        }

        if (!IO::FileExists(resolvedPath)) {
            g_GhostFrames.RemoveRange(0, g_GhostFrames.Length);
            g_GhostLoadedPath = resolvedPath;
            g_GhostReady = false;
            g_GhostStatus = "Ghost file missing: " + resolvedPath;
            return false;
        }

        const string raw = IO::ReadFile(resolvedPath);
        if (raw.Length < 64) {
            g_GhostFrames.RemoveRange(0, g_GhostFrames.Length);
            g_GhostLoadedPath = resolvedPath;
            g_GhostReady = false;
            g_GhostStatus = "Ghost file is too small to derive test frames";
            return false;
        }

        g_GhostFrames.RemoveRange(0, g_GhostFrames.Length);
        const int dataLen = int(raw.Length);
        const int frameCount = ClampInt(dataLen / 3, 240, 1800);

        int cursor = 0;
        float simSpeedKmh = 80.0f + (NextGhostByte(raw, cursor) / 255.0f) * 110.0f;
        float simAngleDeg = 0.0f;
        float simSlip = 0.0f;
        int slideSign = NextGhostByte(raw, cursor) > 127 ? 1 : -1;
        int phaseFramesLeft = 40 + (NextGhostByte(raw, cursor) % 80);
        bool inSlidePhase = false;
        float targetAbsAngle = 0.0f;
        float targetSpeedKmh = simSpeedKmh;

        for (int i = 0; i < frameCount; i++) {
            if (phaseFramesLeft <= 0) {
                const int phaseSelector = NextGhostByte(raw, cursor);
                inSlidePhase = phaseSelector > 70;
                if (inSlidePhase) {
                    const int signSelector = NextGhostByte(raw, cursor);
                    if (signSelector > 90) {
                        slideSign = signSelector > 170 ? 1 : -1;
                    }
                    const float shape = NextGhostByte(raw, cursor) / 255.0f;
                    targetAbsAngle = 12.0f + shape * 22.0f;
                    targetSpeedKmh = 90.0f + (NextGhostByte(raw, cursor) / 255.0f) * 140.0f;
                    phaseFramesLeft = 90 + (NextGhostByte(raw, cursor) % 220);
                } else {
                    targetAbsAngle = (NextGhostByte(raw, cursor) / 255.0f) * 5.0f;
                    targetSpeedKmh = 70.0f + (NextGhostByte(raw, cursor) / 255.0f) * 120.0f;
                    phaseFramesLeft = 25 + (NextGhostByte(raw, cursor) % 95);
                }
            }

            phaseFramesLeft--;

            const float targetAngle = inSlidePhase ? slideSign * targetAbsAngle : 0.0f;
            const float angleAlpha = inSlidePhase ? 0.08f : 0.12f;
            simAngleDeg = Lerp(simAngleDeg, targetAngle, angleAlpha);
            if (!inSlidePhase && Math::Abs(simAngleDeg) < 0.2f) simAngleDeg = 0.0f;

            simSpeedKmh = Lerp(simSpeedKmh, targetSpeedKmh, 0.04f);
            simSlip = Lerp(simSlip, (simAngleDeg / 45.0f) * 5.0f, 0.11f);

            const bool rareAirborne = NextGhostByte(raw, cursor) > 252;
            const bool hasNoiseSignal = NextGhostByte(raw, cursor) > 8;

            GhostFrame@ frame = GhostFrame();
            frame.speedKmh = Clamp(simSpeedKmh, 20.0f, 260.0f);
            frame.rawAngleDeg = Clamp(simAngleDeg, -48.0f, 48.0f);
            frame.lateralSlip = Clamp(simSlip, -7.0f, 7.0f);
            frame.isOnIce = inSlidePhase || NextGhostByte(raw, cursor) > 15;
            frame.isAirborne = !inSlidePhase && rareAirborne;
            frame.hasSignal = frame.speedKmh > 24.0f && (inSlidePhase || hasNoiseSignal || Math::Abs(frame.rawAngleDeg) > 0.6f);
            frame.isDriving = NextGhostByte(raw, cursor) > 1;

            if (Math::Abs(frame.rawAngleDeg) < 0.4f) {
                frame.rawAngleDeg = 0.0f;
            }
            if (!frame.hasSignal) {
                frame.rawAngleDeg = 0.0f;
                frame.lateralSlip = 0.0f;
            }

            g_GhostFrames.InsertLast(frame);
        }

        g_GhostLoadedPath = resolvedPath;
        g_GhostReady = g_GhostFrames.Length > 0;
        g_GhostStatus = g_GhostReady
            ? "Loaded " + Text::Format("%d", g_GhostFrames.Length) + " synthetic frames from " + resolvedPath
            : "Ghost replay frame generation failed";

        ResetGhostPlaybackCursor();
        return g_GhostReady;
    }

    bool BuildFrameInputsFromGhost(float dt, FrameInputs &out input) {
        if (!g_GhostReady || g_GhostFrames.Length == 0) {
            return false;
        }

        const uint index = Math::Min(g_GhostFrameIndex, g_GhostFrames.Length - 1);
        GhostFrame@ sample = g_GhostFrames[index];

        input.dt = Math::Max(0.0f, dt);
        input.speedKmh = sample.speedKmh;
        input.prevSpeedKmh = g_State.speedKmh;
        input.rawAngleDeg = sample.rawAngleDeg;
        input.prevRawAngleDeg = g_State.rawAngleDeg;
        input.lateralSlip = sample.lateralSlip;
        input.prevSmoothAngleDeg = g_State.smoothAngleDeg;
        input.prevSmoothLateralSlip = g_State.smoothLateralSlip;
        input.prevSmoothSpeedDeltaKmhPerSec = g_State.smoothSpeedDeltaKmhPerSec;
        input.isDriving = sample.isDriving;
        input.isAirborne = sample.isAirborne;
        input.isOnIce = sample.isOnIce;
        input.hasSignal = sample.hasSignal;

        const float stepDt = 1.0f / 60.0f;
        g_GhostFrameAccumulator += input.dt * Math::Max(0.1f, S_GhostPlaybackSpeed);
        while (g_GhostFrameAccumulator >= stepDt) {
            g_GhostFrameAccumulator -= stepDt;
            if (g_GhostFrameIndex + 1 < g_GhostFrames.Length) {
                g_GhostFrameIndex++;
            } else if (S_GhostReplayLoop) {
                g_GhostFrameIndex = 0;
            }
        }

        return true;
    }

    void ApplyGhostSelectionFromOption(int optionIndex) {
        if (g_GhostFiles.Length == 0) {
            S_GhostSelectedFile = "";
            g_SelectedGhostOption = 0;
            return;
        }

        const int safe = ClampInt(optionIndex, 0, int(g_GhostFiles.Length) - 1);
        g_SelectedGhostOption = safe;
        S_GhostSelectedFile = g_GhostFiles[safe];
        LoadGhostReplayData(true);
    }

    void RenderGhostPickerWindow() {
        if (!g_ShowGhostPickerOnStartup) return;

        int flags = UI::WindowFlags::AlwaysAutoResize;
        flags |= UI::WindowFlags::NoCollapse;
        if (UI::Begin("Ghost Replay Source", g_ShowGhostPickerOnStartup, flags)) {
            UI::Text("Pick a ghost file from " + ResolveGhostDirectoryPath());
            UI::Text("Selected: " + (S_GhostSelectedFile.Length > 0 ? S_GhostSelectedFile : "(none)"));
            UI::Text("Status: " + g_GhostStatus);

            if (g_GhostFiles.Length == 0) {
                UI::TextDisabled("No .Ghost.gbx files found.");
                if (UI::Button("Refresh List")) {
                    RefreshGhostFileOptions();
                }
            } else {
                if (UI::BeginCombo("Ghost File", S_GhostSelectedFile)) {
                    for (uint i = 0; i < g_GhostFiles.Length; i++) {
                        const bool selected = int(i) == g_SelectedGhostOption;
                        if (UI::Selectable(g_GhostFiles[i], selected)) {
                            ApplyGhostSelectionFromOption(int(i));
                        }
                    }
                    UI::EndCombo();
                }
                if (UI::Button("Use Selected Ghost")) {
                    LoadGhostReplayData(true);
                    g_ShowGhostPickerOnStartup = false;
                }
                UI::SameLine();
                if (UI::Button("Refresh List")) {
                    RefreshGhostFileOptions();
                }
                UI::SameLine();
                if (UI::Button("Close")) {
                    g_ShowGhostPickerOnStartup = false;
                }
            }
        }
        UI::End();
    }

    float ComputeConfidenceValues(bool isDriving, bool isAirborne, bool hasSignal, bool isOnIce, float speedKmh, float rawAngleDeg, float smoothAngleDeg, const CoreConfig &in c) {
        if (!isDriving || isAirborne || !hasSignal || (c.onlyShowOnIce && !isOnIce)) return 0.0f;
        const float speedFactor = Clamp01((speedKmh - c.minSpeedKmh) / 80.0f);
        const float iceFactor = isOnIce ? 1.0f : 0.65f;
        const float jitter = Math::Abs(rawAngleDeg - smoothAngleDeg);
        const float jitterFactor = 1.0f - Clamp01(jitter / 25.0f);
        return Clamp01(speedFactor * iceFactor * jitterFactor);
    }

    FrameOutput EvaluateFrame(const FrameInputs &in input, const CoreConfig &in config) {
        FrameOutput out;

        const bool speedOk = input.speedKmh >= config.minSpeedKmh;
        const bool surfaceOk = !config.onlyShowOnIce || input.isOnIce;
        const bool stateOk = input.isDriving && !input.isAirborne && input.hasSignal && surfaceOk;
        out.isActive = stateOk && speedOk;

        if (!input.isDriving) {
            out.inactiveReason = "not driving";
        } else if (input.isAirborne) {
            out.inactiveReason = "airborne";
        } else if (!input.hasSignal) {
            out.inactiveReason = "low planar velocity";
        } else if (!surfaceOk) {
            out.inactiveReason = "not on ice";
        } else if (!speedOk) {
            out.inactiveReason = "below min speed";
        }

        const float dt = Math::Max(0.0f, input.dt);
        const float alpha = EffectiveAlpha(config.smoothingAlpha, dt);
        out.smoothAngleDeg = input.prevSmoothAngleDeg;
        out.smoothLateralSlip = input.prevSmoothLateralSlip;
        out.smoothSpeedDeltaKmhPerSec = input.prevSmoothSpeedDeltaKmhPerSec;

        if (out.isActive) {
            out.smoothAngleDeg = Lerp(input.prevSmoothAngleDeg, input.rawAngleDeg, alpha);
            out.smoothLateralSlip = Lerp(input.prevSmoothLateralSlip, input.lateralSlip, alpha);
        } else if (config.resetWhenInactive) {
            const float resetAlpha = EffectiveAlpha(0.10f, dt);
            out.smoothAngleDeg = Lerp(input.prevSmoothAngleDeg, 0.0f, resetAlpha);
            out.smoothLateralSlip = Lerp(input.prevSmoothLateralSlip, 0.0f, resetAlpha);
        }

        out.speedDeltaKmhPerSec = (dt > 1e-6f && input.prevSpeedKmh > 0.001f) ? (input.speedKmh - input.prevSpeedKmh) / dt : 0.0f;
        const float deltaAlpha = EffectiveAlpha(0.18f, dt);
        out.smoothSpeedDeltaKmhPerSec = Lerp(input.prevSmoothSpeedDeltaKmhPerSec, out.speedDeltaKmhPerSec, deltaAlpha);
        out.angleOscillationDegPerSec = (dt > 1e-6f && Math::Abs(input.prevRawAngleDeg) > 0.001f) ? Math::Abs(input.rawAngleDeg - input.prevRawAngleDeg) / dt : 0.0f;

        const float absAngle = Math::Abs(out.smoothAngleDeg);
        out.angleScore = ScoreAngleBand(absAngle);
        out.speedScore = ScoreSpeedEfficiency(out.smoothSpeedDeltaKmhPerSec);
        out.stabilityScore = ScoreStability(out.angleOscillationDegPerSec);
        out.efficiencyScore = Clamp01(0.50f * out.angleScore + 0.30f * out.speedScore + 0.20f * out.stabilityScore);
        out.slideState = ClassifySlideState(
            out.isActive,
            out.smoothAngleDeg,
            input.prevSmoothAngleDeg,
            out.smoothSpeedDeltaKmhPerSec,
            out.angleScore,
            out.speedScore,
            out.stabilityScore
        );

        out.confidence = ComputeConfidenceValues(
            input.isDriving,
            input.isAirborne,
            input.hasSignal,
            input.isOnIce,
            input.speedKmh,
            input.rawAngleDeg,
            out.smoothAngleDeg,
            config
        );

        if (!out.isActive) {
            out.efficiencyScore = 0.0f;
            out.angleScore = 0.0f;
            out.speedScore = 0.0f;
            out.stabilityScore = 0.0f;
        }

        return out;
    }

    float ApplyDeadzone(float angleDeg, float deadzoneDeg) {
        const float dz = Math::Max(0.0f, deadzoneDeg);
        if (Math::Abs(angleDeg) <= dz) return 0.0f;
        return angleDeg;
    }

    bool AlmostEqual(float a, float b, float eps) {
        return Math::Abs(a - b) <= eps;
    }

    void AppendTestResult(bool ok, const string &in label, int &inout passCount, int &inout failCount, string &inout report) {
        if (ok) {
            passCount++;
            report += "PASS: " + label + "\n";
        } else {
            failCount++;
            report += "FAIL: " + label + "\n";
        }
    }

    void RunOfflineSelfTests() {
        int passCount = 0;
        int failCount = 0;
        string report = "Offline self-tests\n";

        {
            const vec3 fromDir = vec3(0.0f, 0.0f, 1.0f);
            const vec3 right45 = SafeNormalize(vec3(1.0f, 0.0f, 1.0f));
            const vec3 left45 = SafeNormalize(vec3(-1.0f, 0.0f, 1.0f));
            const float a0 = SignedAngleDeg(fromDir, fromDir, WORLD_UP);
            const float ar = SignedAngleDeg(fromDir, right45, WORLD_UP);
            const float al = SignedAngleDeg(fromDir, left45, WORLD_UP);
            AppendTestResult(AlmostEqual(a0, 0.0f, 0.01f), "SignedAngle straight ~= 0", passCount, failCount, report);
            AppendTestResult(AlmostEqual(ar, 45.0f, 0.01f), "SignedAngle right ~= +45", passCount, failCount, report);
            AppendTestResult(AlmostEqual(al, -45.0f, 0.01f), "SignedAngle left ~= -45", passCount, failCount, report);
        }

        {
            const float dz0 = ApplyDeadzone(0.4f, 0.6f);
            const float dz1 = ApplyDeadzone(1.2f, 0.6f);
            AppendTestResult(AlmostEqual(dz0, 0.0f, 0.0001f), "Deadzone suppresses small angle", passCount, failCount, report);
            AppendTestResult(AlmostEqual(dz1, 1.2f, 0.0001f), "Deadzone keeps large angle", passCount, failCount, report);
        }

        {
            CoreConfig c;
            c.minSpeedKmh = 40.0f;
            c.onlyShowOnIce = false;
            c.smoothingAlpha = 0.20f;
            c.resetWhenInactive = true;

            FrameInputs i;
            i.dt = 1.0f / 60.0f;
            i.isDriving = true;
            i.isAirborne = false;
            i.isOnIce = true;
            i.hasSignal = true;
            i.speedKmh = 120.0f;
            i.rawAngleDeg = 30.0f;
            i.lateralSlip = 1.5f;
            i.prevSmoothAngleDeg = 10.0f;
            i.prevSmoothLateralSlip = 0.5f;

            FrameOutput o = EvaluateFrame(i, c);
            AppendTestResult(o.isActive, "EvaluateFrame marks active state", passCount, failCount, report);
            AppendTestResult(o.smoothAngleDeg > i.prevSmoothAngleDeg, "EvaluateFrame smooth angle moves toward raw", passCount, failCount, report);
            AppendTestResult(o.confidence > 0.0f, "EvaluateFrame confidence positive when valid", passCount, failCount, report);
        }

        {
            CoreConfig c;
            c.minSpeedKmh = 80.0f;
            c.onlyShowOnIce = true;
            c.smoothingAlpha = 0.20f;
            c.resetWhenInactive = true;

            FrameInputs i;
            i.dt = 1.0f / 60.0f;
            i.isDriving = true;
            i.isAirborne = false;
            i.isOnIce = false;
            i.hasSignal = true;
            i.speedKmh = 70.0f;
            i.rawAngleDeg = 20.0f;
            i.lateralSlip = 1.0f;
            i.prevSmoothAngleDeg = 15.0f;
            i.prevSmoothLateralSlip = 0.8f;

            FrameOutput o = EvaluateFrame(i, c);
            AppendTestResult(!o.isActive, "EvaluateFrame inactive when not on ice and below speed", passCount, failCount, report);
            AppendTestResult(o.confidence <= 0.001f, "EvaluateFrame confidence near zero for invalid state", passCount, failCount, report);
        }

        g_SelfTestsPassed = failCount == 0;
        report += "Results: " + Text::Format("%d", passCount) + " passed, " + Text::Format("%d", failCount) + " failed";
        g_SelfTestReport = report;
    }

    void Tick(float dt) {
        dt = Math::Max(0.0f, dt);
        const float prevSpeedKmh = g_State.speedKmh;
        const float prevRawAngleDeg = g_State.rawAngleDeg;
        const float prevSmoothSpeedDeltaKmhPerSec = g_State.smoothSpeedDeltaKmhPerSec;

        if (S_EnableGhostReplay) {
            LoadGhostReplayData(false);

            FrameInputs ghostInput;
            if (BuildFrameInputsFromGhost(dt, ghostInput)) {
                g_State.isDriving = ghostInput.isDriving;
                g_State.isAirborne = ghostInput.isAirborne;
                g_State.isOnIce = ghostInput.isOnIce;
                g_State.hasSignal = ghostInput.hasSignal;
                g_State.speedKmh = ghostInput.speedKmh;
                g_State.rawAngleDeg = ghostInput.rawAngleDeg;
                g_State.lateralSlip = ghostInput.lateralSlip;

                const FrameOutput ghostOut = EvaluateFrame(ghostInput, BuildCoreConfig());
                g_State.isActive = ghostOut.isActive;
                g_State.inactiveReason = ghostOut.inactiveReason;
                g_State.confidence = ghostOut.confidence;
                g_State.smoothAngleDeg = ghostOut.smoothAngleDeg;
                g_State.smoothLateralSlip = ghostOut.smoothLateralSlip;
                g_State.speedDeltaKmhPerSec = ghostOut.speedDeltaKmhPerSec;
                g_State.smoothSpeedDeltaKmhPerSec = ghostOut.smoothSpeedDeltaKmhPerSec;
                g_State.angleOscillationDegPerSec = ghostOut.angleOscillationDegPerSec;
                g_State.angleScore = ghostOut.angleScore;
                g_State.speedScore = ghostOut.speedScore;
                g_State.stabilityScore = ghostOut.stabilityScore;
                g_State.efficiencyScore = ghostOut.efficiencyScore;
                g_State.slideState = ghostOut.slideState;
                return;
            }
        }

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

        FrameInputs input;
        input.dt = dt;
        input.speedKmh = g_State.speedKmh;
        input.prevSpeedKmh = prevSpeedKmh;
        input.rawAngleDeg = g_State.rawAngleDeg;
        input.prevRawAngleDeg = prevRawAngleDeg;
        input.lateralSlip = g_State.lateralSlip;
        input.prevSmoothAngleDeg = g_State.smoothAngleDeg;
        input.prevSmoothLateralSlip = g_State.smoothLateralSlip;
        input.prevSmoothSpeedDeltaKmhPerSec = prevSmoothSpeedDeltaKmhPerSec;
        input.isDriving = g_State.isDriving;
        input.isAirborne = g_State.isAirborne;
        input.isOnIce = g_State.isOnIce;
        input.hasSignal = g_State.hasSignal;

        const FrameOutput out = EvaluateFrame(input, BuildCoreConfig());
        g_State.isActive = out.isActive;
        g_State.inactiveReason = out.inactiveReason;
        g_State.confidence = out.confidence;
        g_State.smoothAngleDeg = out.smoothAngleDeg;
        g_State.smoothLateralSlip = out.smoothLateralSlip;
        g_State.speedDeltaKmhPerSec = out.speedDeltaKmhPerSec;
        g_State.smoothSpeedDeltaKmhPerSec = out.smoothSpeedDeltaKmhPerSec;
        g_State.angleOscillationDegPerSec = out.angleOscillationDegPerSec;
        g_State.angleScore = out.angleScore;
        g_State.speedScore = out.speedScore;
        g_State.stabilityScore = out.stabilityScore;
        g_State.efficiencyScore = out.efficiencyScore;
        g_State.slideState = out.slideState;
    }

    void RenderHud() {
        if (!S_EnableHud) return;

        UI::SetNextWindowPos(int(S_HudX), int(S_HudY), UI::Cond::Always);
        const int hudHeight = S_EnableV2Gauge ? 280 : 160;
        UI::SetNextWindowSize(int(340 * S_HudScale), int(hudHeight * S_HudScale), UI::Cond::Always);

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
        if (S_EnableGhostReplay && g_GhostReady) {
            HudTextLine("Source: Ghost Replay Test");
        }

        const float meterMaxAngleDeg = Math::Max(1.0f, S_HudMeterMaxAngleDeg);
        const string meterBar = BuildMeterBar(g_State.smoothAngleDeg, meterMaxAngleDeg, HUD_METER_HALF_WIDTH);
        const string meterScale = BuildMeterScaleLabel(meterMaxAngleDeg, HUD_METER_HALF_WIDTH);
        HudTextLine(" " + meterScale);
        HudTextLine(meterBar);

        if (S_EnableV2Gauge) {
            UI::Separator();
            const string efficiencyText = "Efficiency: " + Text::Format("%.0f", g_State.efficiencyScore * 100.0f) + "%";
            UI::PushStyleColor(UI::Col::PlotHistogram, ScoreColor(g_State.efficiencyScore));
            UI::ProgressBar(g_State.efficiencyScore, vec2(-1.0f, 0.0f), efficiencyText);
            UI::PopStyleColor();

            HudTextLine("Speed d: " + Text::Format("%+.1f km/h/s", g_State.smoothSpeedDeltaKmhPerSec));
            HudColoredLine("State: " + g_State.slideState, SlideStateColor(g_State.slideState));

            UI::PushStyleColor(UI::Col::PlotHistogram, ScoreColor(g_State.angleScore));
            UI::ProgressBar(g_State.angleScore, vec2(-1.0f, 0.0f), "Angle score");
            UI::PopStyleColor();

            UI::PushStyleColor(UI::Col::PlotHistogram, ScoreColor(g_State.speedScore));
            UI::ProgressBar(g_State.speedScore, vec2(-1.0f, 0.0f), "Speed score");
            UI::PopStyleColor();

            UI::PushStyleColor(UI::Col::PlotHistogram, ScoreColor(g_State.stabilityScore));
            UI::ProgressBar(g_State.stabilityScore, vec2(-1.0f, 0.0f), "Stability score");
            UI::PopStyleColor();
        }

        if (g_State.isActive) {
            if (!S_EnableV2Gauge) {
                UI::Text("State: active");
            }
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
            UI::Text("Speed delta: " + Text::Format("%+.2f km/h/s", g_State.smoothSpeedDeltaKmhPerSec));
            UI::Text("Oscillation: " + Text::Format("%.1f deg/s", g_State.angleOscillationDegPerSec));
            UI::Text("V2 state: " + g_State.slideState);
            UI::Text("V2 scores: A=" + Text::Format("%.2f", g_State.angleScore)
                + " S=" + Text::Format("%.2f", g_State.speedScore)
                + " St=" + Text::Format("%.2f", g_State.stabilityScore)
                + " E=" + Text::Format("%.2f", g_State.efficiencyScore));

            UI::Separator();
            UI::Text("Ghost replay mode: " + (S_EnableGhostReplay ? "enabled" : "disabled"));
            UI::Text("Ghost directory: " + ResolveGhostDirectoryPath());
            UI::Text("Ghost selected: " + (S_GhostSelectedFile.Length > 0 ? S_GhostSelectedFile : "(none)"));
            UI::Text("Ghost status: " + g_GhostStatus);
            if (g_GhostFiles.Length > 0 && UI::BeginCombo("Ghost File", S_GhostSelectedFile)) {
                for (uint i = 0; i < g_GhostFiles.Length; i++) {
                    const bool selected = int(i) == g_SelectedGhostOption;
                    if (UI::Selectable(g_GhostFiles[i], selected)) {
                        ApplyGhostSelectionFromOption(int(i));
                    }
                }
                UI::EndCombo();
            }
            if (UI::Button("Refresh Ghost List")) {
                RefreshGhostFileOptions();
            }
            UI::SameLine();
            if (UI::Button("Reload Ghost Replay Data")) {
                LoadGhostReplayData(true);
            }
            UI::SameLine();
            if (UI::Button("Reset Ghost Playback")) {
                ResetGhostPlaybackCursor();
            }
            if (g_GhostReady && g_GhostFrames.Length > 0) {
                const float progress = g_GhostFrames.Length <= 1
                    ? 1.0f
                    : float(g_GhostFrameIndex) / float(g_GhostFrames.Length - 1);
                UI::ProgressBar(progress, vec2(360.0f, 0.0f), "Ghost frame " + Text::Format("%d", g_GhostFrameIndex + 1) + "/" + Text::Format("%d", g_GhostFrames.Length));
                UI::Text("Raw angle preview");
                UI::Text(BuildMeterBar(g_State.rawAngleDeg, Math::Max(1.0f, S_HudMeterMaxAngleDeg), HUD_METER_HALF_WIDTH));
                UI::Text("Smoothed angle preview");
                UI::Text(BuildMeterBar(g_State.smoothAngleDeg, Math::Max(1.0f, S_HudMeterMaxAngleDeg), HUD_METER_HALF_WIDTH));
            }

            if (S_EnableOfflineSelfTests) {
                UI::Separator();
                if (UI::Button("Run Offline Self-Tests")) {
                    RunOfflineSelfTests();
                }
                if (g_SelfTestsPassed) {
                    UI::TextColored(vec4(0.35f, 0.95f, 0.45f, 1.0f), "Self-tests: PASS");
                } else {
                    UI::TextColored(vec4(1.0f, 0.42f, 0.42f, 1.0f), "Self-tests: NOT PASSING / NOT RUN");
                }
                UI::InputTextMultiline("Results", g_SelfTestReport, vec2(560.0f, 180.0f));
            }
        }
        UI::End();
    }
}

void Main() {
    ISA::RefreshGhostFileOptions();
    ISA::LoadGhostReplayData(false);
}

void Update(float dt) {
    ISA::Tick(dt);
}

void Render() {
    ISA::RenderHud();
}

void RenderInterface() {
    ISA::RenderGhostPickerWindow();
    ISA::RenderDebugWindow();
}

void RenderMenu() {
    if (UI::MenuItem("Ice Slide Assist", "", g_MenuVisible)) {
        g_MenuVisible = !g_MenuVisible;
    }
}
