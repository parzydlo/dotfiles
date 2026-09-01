#Requires -Version 7.0
<#
.SYNOPSIS
Sets an app's Windows per-app mixer volume when it launches.

Electron apps install each update into a new versioned folder. Windows keys per-app volume to
the exe path, so every update produces a fresh mixer entry at 1.0 and the previously chosen
level is lost. This wraps the app's launch: start it, wait for its audio session to appear, set
the level, exit.

.EXAMPLE
app-volume.ps1 -Launch Discord      # start Discord and set its level
app-volume.ps1 -Once Discord        # set the level of an already-running Discord
app-volume.ps1 -List                # dump every audio session, for writing patterns
app-volume.ps1 -Install             # point the launch surfaces at this wrapper
app-volume.ps1 -Uninstall           # restore the original launch surfaces
#>
[CmdletBinding(DefaultParameterSetName = 'List')]
param(
    [Parameter(ParameterSetName = 'Launch', Mandatory, Position = 0)][string]$Launch,
    [Parameter(ParameterSetName = 'Once', Mandatory, Position = 0)][string]$Once,
    [Parameter(ParameterSetName = 'List')][switch]$List,
    [Parameter(ParameterSetName = 'Install')][switch]$Install,
    [Parameter(ParameterSetName = 'Uninstall')][switch]$Uninstall,
    [int]$TimeoutSeconds = 120
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ConfigDir  = $PSScriptRoot
$ConfigPath = Join-Path $ConfigDir 'apps.json'
$LogPath    = Join-Path $ConfigDir 'app-volume.log'
$BackupPath = Join-Path $ConfigDir 'wiring-backup.json'

function Write-Log {
    param([string]$Message, [switch]$AsError)
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    try { Add-Content -LiteralPath $LogPath -Value $line -Encoding utf8 } catch { }
    if ($AsError) { Write-Warning $Message } else { Write-Host $line }
}

function Expand-Path { param([string]$Path) [Environment]::ExpandEnvironmentVariables($Path) }

function Get-AppConfig {
    param([string]$Name)
    if (-not (Test-Path -LiteralPath $ConfigPath)) { throw "Config not found: $ConfigPath" }
    $all = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
    $entry = $all | Where-Object { $_.name -eq $Name }
    if (-not $entry) { throw "No entry named '$Name' in $ConfigPath" }
    $entry
}

# ---------------------------------------------------------------------------
# Core Audio interop.
#
# Every COM call lives in here on purpose. PowerShell 7 cannot cast a
# System.__ComObject to a ComImport interface (Windows PowerShell 5.1 could), so the
# enumerator has to be created and consumed inside C#. Method declaration order is vtable
# order and must not be reordered; IAudioSessionControl2 carries the full
# IAudioSessionControl prefix it inherits.
# ---------------------------------------------------------------------------
function Initialize-Audio {
    if ('AppVolume.Mixer' -as [type]) { return }
    Add-Type -Language CSharp -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Globalization;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;

namespace AppVolume {

 [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
 class MMDeviceEnumeratorComObject { }

 [ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
 interface IMMDeviceEnumerator {
  int EnumAudioEndpoints(int dataFlow, int stateMask, out IMMDeviceCollection devices);
  int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice device);
 }

 [ComImport, Guid("0BD7A1BE-7A1A-44DB-8397-CC5392387B5E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
 interface IMMDeviceCollection {
  int GetCount(out int count);
  int Item(int index, out IMMDevice device);
 }

 [ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
 interface IMMDevice {
  int Activate(ref Guid iid, uint clsCtx, IntPtr activationParams, [MarshalAs(UnmanagedType.IUnknown)] out object iface);
  int OpenPropertyStore(uint access, out IntPtr store);
  int GetId([MarshalAs(UnmanagedType.LPWStr)] out string id);
  int GetState(out uint state);
 }

 [ComImport, Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
 interface IAudioSessionManager2 {
  int GetAudioSessionControl(IntPtr sessionGuid, uint flags, out IntPtr control);
  int GetSimpleAudioVolume(IntPtr sessionGuid, uint flags, out IntPtr volume);
  int GetSessionEnumerator(out IAudioSessionEnumerator sessions);
 }

 [ComImport, Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
 interface IAudioSessionEnumerator {
  int GetCount(out int count);
  int GetSession(int index, out IAudioSessionControl2 session);
 }

 [ComImport, Guid("BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
 interface IAudioSessionControl2 {
  int GetState(out int state);
  int GetDisplayName([MarshalAs(UnmanagedType.LPWStr)] out string name);
  int SetDisplayName([MarshalAs(UnmanagedType.LPWStr)] string name, IntPtr ctx);
  int GetIconPath([MarshalAs(UnmanagedType.LPWStr)] out string path);
  int SetIconPath([MarshalAs(UnmanagedType.LPWStr)] string path, IntPtr ctx);
  int GetGroupingParam(out Guid group);
  int SetGroupingParam(ref Guid group, IntPtr ctx);
  int RegisterAudioSessionNotification(IntPtr notify);
  int UnregisterAudioSessionNotification(IntPtr notify);
  int GetSessionIdentifier([MarshalAs(UnmanagedType.LPWStr)] out string id);
  int GetSessionInstanceIdentifier([MarshalAs(UnmanagedType.LPWStr)] out string id);
  int GetProcessId(out uint pid);
  int IsSystemSoundsSession();
  int SetDuckingPreference(bool optOut);
 }

 [ComImport, Guid("87CE5498-68D6-44E5-9215-6DA47EF883D8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
 interface ISimpleAudioVolume {
  int SetMasterVolume(float level, ref Guid ctx);
  int GetMasterVolume(out float level);
  int SetMute(bool mute, ref Guid ctx);
  int GetMute(out bool mute);
 }

 public static class Mixer {

  const int eRender = 0;
  const int DEVICE_STATE_ACTIVE = 1;
  const uint CLSCTX_ALL = 23;

  static string F(float v) { return v.ToString("0.000", CultureInfo.InvariantCulture); }

  static bool IsLive(uint pid) {
   if (pid == 0) return false;
   try { using (Process.GetProcessById((int)pid)) { return true; } } catch { return false; }
  }

  // Walks every active render endpoint. Yields (endpointId, session) pairs.
  static IEnumerable<KeyValuePair<string, IAudioSessionControl2>> Sessions() {
   var enumerator = (IMMDeviceEnumerator)new MMDeviceEnumeratorComObject();
   IMMDeviceCollection devices;
   if (enumerator.EnumAudioEndpoints(eRender, DEVICE_STATE_ACTIVE, out devices) != 0) yield break;
   int deviceCount;
   devices.GetCount(out deviceCount);
   Guid iid = typeof(IAudioSessionManager2).GUID;

   for (int d = 0; d < deviceCount; d++) {
    string endpointId = null;
    IAudioSessionEnumerator sessions = null;
    int sessionCount = 0;
    // A single unhealthy endpoint must not abort the whole pass.
    try {
     IMMDevice device;
     devices.Item(d, out device);
     device.GetId(out endpointId);
     object manager;
     device.Activate(ref iid, CLSCTX_ALL, IntPtr.Zero, out manager);
     ((IAudioSessionManager2)manager).GetSessionEnumerator(out sessions);
     sessions.GetCount(out sessionCount);
    } catch { continue; }

    for (int i = 0; i < sessionCount; i++) {
     IAudioSessionControl2 session = null;
     try { sessions.GetSession(i, out session); } catch { continue; }
     if (session != null) yield return new KeyValuePair<string, IAudioSessionControl2>(endpointId, session);
    }
   }
  }

  /// Every session on every active render endpoint, for debugging and writing patterns.
  public static List<string> List() {
   var rows = new List<string>();
   string lastEndpoint = null;
   foreach (var pair in Sessions()) {
    if (pair.Key != lastEndpoint) { rows.Add("endpoint " + pair.Key); lastEndpoint = pair.Key; }
    var s = pair.Value;
    uint pid; s.GetProcessId(out pid);
    int state; s.GetState(out state);
    float level; ((ISimpleAudioVolume)s).GetMasterVolume(out level);
    string id; s.GetSessionIdentifier(out id);
    string name = IsLive(pid) ? Process.GetProcessById((int)pid).ProcessName : "(not running)";
    rows.Add(string.Format("  pid={0,-6} state={1} vol={2} {3}", pid, state, F(level), name));
    rows.Add("    id       " + id);
    // An app can register several sessions sharing one exe path (Discord registers a
    // separate one for notification sounds and for voice output). These are the fields
    // that can tell them apart.
    string display = null, icon = null, instance = null;
    Guid group = Guid.Empty;
    try { s.GetDisplayName(out display); } catch { }
    try { s.GetIconPath(out icon); } catch { }
    try { s.GetSessionInstanceIdentifier(out instance); } catch { }
    try { s.GetGroupingParam(out group); } catch { }
    bool isSystem = false;
    try { isSystem = (s.IsSystemSoundsSession() == 0); } catch { }
    rows.Add("    display  " + (string.IsNullOrEmpty(display) ? "(empty)" : display));
    rows.Add("    icon     " + (string.IsNullOrEmpty(icon) ? "(empty)" : icon));
    rows.Add("    group    " + group);
    rows.Add("    sysSnd   " + isSystem);
    rows.Add("    instance " + instance);
   }
   return rows;
  }

  /// Sets every live session whose identifier matches pattern.
  /// Returns one "status|pid|old|new" row per match: set, keep, or fail.
  ///
  /// Dead sessions are skipped by design. Windows keeps expired sessions in the enumerator
  /// (older Discord builds linger there with pid 0), and requiring a live pid is what makes
  /// this pick the process we just started rather than a leftover.
  ///
  /// Inactive sessions ARE set. State 0 is normal for an app that has registered its session
  /// but not yet played a sound, which is exactly the window worth catching.
  /// pidFilter narrows the match to specific processes. null means no filter; an empty array
  /// means a filter is configured but no process currently qualifies, so nothing matches and
  /// the caller keeps polling.
  public static List<string> Apply(string pattern, float volume, uint[] pidFilter) {
   var rows = new List<string>();
   var rx = new Regex(pattern, RegexOptions.IgnoreCase);
   foreach (var pair in Sessions()) {
    var s = pair.Value;
    string id;
    try { s.GetSessionIdentifier(out id); } catch { continue; }
    if (id == null || !rx.IsMatch(id)) continue;
    uint pid; s.GetProcessId(out pid);
    if (!IsLive(pid)) continue;
    if (pidFilter != null && Array.IndexOf(pidFilter, pid) < 0) continue;

    var vol = (ISimpleAudioVolume)s;
    float current;
    if (vol.GetMasterVolume(out current) != 0) continue;

    if (Math.Abs(current - volume) < 0.001f) {
     rows.Add("keep|" + pid + "|" + F(current) + "|" + F(volume));
    } else {
     Guid ctx = Guid.Empty;
     int hr = vol.SetMasterVolume(volume, ref ctx);
     rows.Add((hr == 0 ? "set" : "fail") + "|" + pid + "|" + F(current) + "|" + F(volume));
    }
   }
   return rows;
  }
 }
}
'@
}

function Get-SessionPidFilter {
    <#
    Restricts which of an app's processes count, for apps that register more than one mixer
    session. Discord registers two under the same exe path and they are distinguishable only
    by process:

      --type=renderer                                       -> voice chat output
      --type=utility --utility-sub-type=audio.mojom.AudioService -> notification sounds

    Discord's voice engine opens WASAPI directly from the renderer, while notification sounds
    are ordinary web audio and go through Chromium's audio service. Session identifier,
    display name, icon path and grouping param cannot tell the two apart: the identifiers are
    byte-identical, display and icon are empty, and the grouping GUID is random per session.

    Returns $null when no filter is configured, or a possibly-empty pid array when one is.
    Empty means "configured but nothing qualifies yet", which keeps the caller polling.
    #>
    param($App)

    if (-not ($App.PSObject.Properties.Name -contains 'processMatch') -or
        [string]::IsNullOrWhiteSpace($App.processMatch)) { return $null }

    $procs = Get-CimInstance Win32_Process -Filter "Name='$($App.process).exe'" -ErrorAction SilentlyContinue
    $ids = @($procs | Where-Object { $_.CommandLine -and $_.CommandLine -match $App.processMatch } |
             Select-Object -ExpandProperty ProcessId)
    # Unary comma: without it PowerShell unrolls a 0- or 1-element array and the "no filter"
    # meaning of $null would come back by accident.
    return , [uint32[]]$ids
}

function Set-AppVolume {
    <#
    Polls until a live matching session appears, then sets it. Returns $true if anything
    matched. Poll rather than IAudioSessionNotification: the callback interface needs a COM
    class implemented in the C# block and a message pump, which is a lot of machinery to
    shave a few hundred milliseconds off a once-per-launch script.
    #>
    param($App, [int]$Seconds)

    Initialize-Audio
    $volume   = [float]$App.volume
    $deadline = (Get-Date).AddSeconds($Seconds)

    while ($true) {
        # Recomputed every pass: the process that owns the session may not exist yet. On the
        # observed 2026-09-01 launch the renderer appeared 1s in and the audio service 2s in.
        $pidFilter = Get-SessionPidFilter -App $App
        $rows = [AppVolume.Mixer]::Apply($App.pattern, $volume, $pidFilter)
        if ($rows.Count -gt 0) {
            foreach ($row in $rows) {
                $status, $processId, $old, $new = $row -split '\|'
                switch ($status) {
                    'set'  { Write-Log "$($App.name): pid $processId $old -> $new" }
                    'keep' { Write-Log "$($App.name): pid $processId already at $new" }
                    'fail' { Write-Log "$($App.name): pid $processId FAILED to set $old -> $new" -AsError }
                }
            }
            return $true
        }
        if ((Get-Date) -ge $deadline) { return $false }
        Start-Sleep -Milliseconds 500
    }
}

# ---------------------------------------------------------------------------
# Launch surfaces. Discord's updater rewrites its own shortcuts, so -Launch re-asserts this
# wiring after each run rather than trusting -Install to hold.
# ---------------------------------------------------------------------------
function Get-PwshPath {
    <#
    Prefer the app execution alias. pwsh is installed from the Store here, so
    (Get-Process -Id $PID).Path is
    C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.5.0_x64__8wekyb3d8bbwe\pwsh.exe,
    which is version-pinned and would break on the next PowerShell update. That is the same
    bug this script exists to fix, so baking it into the Run key would be self-defeating.
    The alias under LOCALAPPDATA\Microsoft\WindowsApps is a stable reparse point.
    #>
    $alias = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\pwsh.exe'
    if (Test-Path -LiteralPath $alias) { return $alias }
    $perMachine = 'C:\Program Files\PowerShell\7\pwsh.exe'
    if (Test-Path -LiteralPath $perMachine) { return $perMachine }
    (Get-Process -Id $PID).Path
}

function Get-WrapperCommand {
    param($App)
    $pwshPath = Get-PwshPath
    $arguments = '-NoLogo -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}" -Launch {1}' -f `
        (Join-Path $ConfigDir 'app-volume.ps1'), $App.name
    [pscustomobject]@{ Path = $pwshPath; Arguments = $arguments }
}

function Get-RunKeyPath { 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run' }

function Save-WiringBackup {
    <# Records the original targets once, so -Uninstall can put them back. Never overwrites
       an existing backup: after -Install the live values are ours, not the originals. #>
    param($App)
    if (Test-Path -LiteralPath $BackupPath) { return }

    $shell = New-Object -ComObject WScript.Shell
    $shortcuts = @()
    foreach ($raw in $App.shortcuts) {
        $path = Expand-Path $raw
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $lnk = $shell.CreateShortcut($path)
        $shortcuts += [pscustomobject]@{
            path             = $path
            targetPath       = $lnk.TargetPath
            arguments        = $lnk.Arguments
            workingDirectory = $lnk.WorkingDirectory
            iconLocation     = $lnk.IconLocation
            windowStyle      = $lnk.WindowStyle
        }
    }

    $runValue = $null
    try { $runValue = (Get-ItemProperty -LiteralPath (Get-RunKeyPath) -Name $App.runKey).($App.runKey) } catch { }

    [pscustomobject]@{ app = $App.name; runKey = $App.runKey; runValue = $runValue; shortcuts = $shortcuts } |
        ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $BackupPath -Encoding utf8
    Write-Log "backed up original launch surfaces to $BackupPath"
}

function Test-Wiring {
    param($App)
    $cmd = Get-WrapperCommand -App $App
    try {
        $runValue = (Get-ItemProperty -LiteralPath (Get-RunKeyPath) -Name $App.runKey -ErrorAction Stop).($App.runKey)
    } catch { return $false }
    if ($runValue -notlike "*app-volume.ps1*") { return $false }

    $shell = New-Object -ComObject WScript.Shell
    foreach ($raw in $App.shortcuts) {
        $path = Expand-Path $raw
        if (-not (Test-Path -LiteralPath $path)) { continue }
        $lnk = $shell.CreateShortcut($path)
        if ($lnk.TargetPath -ne $cmd.Path -or $lnk.Arguments -ne $cmd.Arguments) { return $false }
    }
    return $true
}

function Set-Wiring {
    param($App)
    Save-WiringBackup -App $App
    $cmd  = Get-WrapperCommand -App $App
    $icon = Expand-Path $App.icon

    Set-ItemProperty -LiteralPath (Get-RunKeyPath) -Name $App.runKey -Value ('"{0}" {1}' -f $cmd.Path, $cmd.Arguments)
    Write-Log "wired Run\$($App.runKey)"

    $shell = New-Object -ComObject WScript.Shell
    foreach ($raw in $App.shortcuts) {
        $path = Expand-Path $raw
        if (-not (Test-Path -LiteralPath $path)) { Write-Log "shortcut absent, skipped: $path"; continue }
        $lnk = $shell.CreateShortcut($path)
        $lnk.TargetPath       = $cmd.Path
        $lnk.Arguments        = $cmd.Arguments
        $lnk.WorkingDirectory = $ConfigDir
        # Keep the app's own icon: the shortcut now points at pwsh.exe, which would otherwise
        # put a terminal icon on the taskbar pin and in the Start menu.
        if (Test-Path -LiteralPath $icon) { $lnk.IconLocation = "$icon,0" }
        $lnk.WindowStyle = 7   # minimized, belt and braces alongside -WindowStyle Hidden
        $lnk.Save()
        Write-Log "wired shortcut: $path"
    }
}

function Restore-Wiring {
    if (-not (Test-Path -LiteralPath $BackupPath)) { throw "No backup at $BackupPath" }
    $backup = Get-Content -LiteralPath $BackupPath -Raw | ConvertFrom-Json

    if ($backup.runValue) {
        Set-ItemProperty -LiteralPath (Get-RunKeyPath) -Name $backup.runKey -Value $backup.runValue
        Write-Log "restored Run\$($backup.runKey)"
    }
    $shell = New-Object -ComObject WScript.Shell
    foreach ($entry in $backup.shortcuts) {
        $lnk = $shell.CreateShortcut($entry.path)
        $lnk.TargetPath       = $entry.targetPath
        $lnk.Arguments        = $entry.arguments
        $lnk.WorkingDirectory = $entry.workingDirectory
        $lnk.IconLocation     = $entry.iconLocation
        $lnk.WindowStyle      = $entry.windowStyle
        $lnk.Save()
        Write-Log "restored shortcut: $($entry.path)"
    }
}

# ---------------------------------------------------------------------------
# Modes
# ---------------------------------------------------------------------------
switch ($PSCmdlet.ParameterSetName) {

    'List' {
        Initialize-Audio
        [AppVolume.Mixer]::List()
    }

    'Once' {
        $app = Get-AppConfig -Name $Once
        if (-not (Set-AppVolume -App $app -Seconds 5)) {
            Write-Log "$($app.name): no live audio session matched" -AsError
            exit 1
        }
    }

    'Install' {
        $all = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
        foreach ($app in $all) { Set-Wiring -App $app }
    }

    'Uninstall' { Restore-Wiring }

    'Launch' {
        $app = Get-AppConfig -Name $Launch
        $exitCode = 0
        try {
            $running = @(Get-Process -Name $app.process -ErrorAction SilentlyContinue)
            if ($running.Count -eq 0) {
                # Start first, compile second. Add-Type costs a second or two of Roslyn, and
                # running it after the launch overlaps that with the app's own startup instead
                # of delaying the window the user just asked for.
                $target = Expand-Path $app.launch.path
                Start-Process -FilePath $target -ArgumentList $app.launch.args
                Write-Log "$($app.name): launched $target $($app.launch.args -join ' ')"
                $wait = $TimeoutSeconds
            } else {
                Write-Log "$($app.name): already running (pid $($running[0].Id)), not launching a second instance"
                $wait = 15
            }

            if (-not (Set-AppVolume -App $app -Seconds $wait)) {
                Write-Log "$($app.name): no live audio session appeared within ${wait}s" -AsError
                $exitCode = 1
            }
        } catch {
            Write-Log "$($app.name): $($_.Exception.Message)" -AsError
            $exitCode = 1
        }

        # Repair the launch surfaces if the app's updater has overwritten them. Done last so a
        # failure here cannot stop the app from starting or the volume from being set.
        try {
            if (-not (Test-Wiring -App $app)) {
                Write-Log "$($app.name): launch surfaces were overwritten, re-applying"
                Set-Wiring -App $app
            }
        } catch {
            Write-Log "$($app.name): wiring check failed: $($_.Exception.Message)" -AsError
        }

        exit $exitCode
    }
}
