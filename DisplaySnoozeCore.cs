using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Threading;

internal static class DisplaySnoozeCore
{
    private const int HWND_BROADCAST = 0xffff;
    private const int VK_ESCAPE = 0x1b;
    private const int WM_SYSCOMMAND = 0x0112;
    private const int SC_MONITORPOWER = 0xf170;
    private const byte VCP_POWER_MODE = 0xd6;
    private const uint VCP_POWER_OFF_SOFT = 0x04;
    private static readonly IntPtr MONITOR_OFF = new IntPtr(2);

    private sealed class Options
    {
        public int GuardSeconds = 600;
        public int IntervalSeconds = 4;
    }

    [Flags]
    private enum SendMessageTimeoutFlags : uint
    {
        SMTO_ABORTIFHUNG = 0x0002
    }

#pragma warning disable 0649
    private struct Rect
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;
    }
#pragma warning restore 0649

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct PhysicalMonitor
    {
        public IntPtr Handle;

        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string Description;
    }

    private delegate bool MonitorEnumProc(IntPtr monitor, IntPtr hdc, ref Rect rect, IntPtr data);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SendMessageTimeout(
        IntPtr hWnd,
        uint msg,
        IntPtr wParam,
        IntPtr lParam,
        SendMessageTimeoutFlags flags,
        uint timeout,
        out IntPtr result);

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    [DllImport("user32.dll")]
    private static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr clipRect, MonitorEnumProc callback, IntPtr data);

    [DllImport("dxva2.dll", SetLastError = true)]
    private static extern bool GetNumberOfPhysicalMonitorsFromHMONITOR(IntPtr monitor, out uint physicalMonitorCount);

    [DllImport("dxva2.dll", SetLastError = true)]
    private static extern bool GetPhysicalMonitorsFromHMONITOR(
        IntPtr monitor,
        uint physicalMonitorCount,
        [Out] PhysicalMonitor[] physicalMonitors);

    [DllImport("dxva2.dll", SetLastError = true)]
    private static extern bool DestroyPhysicalMonitors(uint physicalMonitorCount, PhysicalMonitor[] physicalMonitors);

    [DllImport("dxva2.dll", SetLastError = true)]
    private static extern bool SetVCPFeature(IntPtr physicalMonitor, byte vcpCode, uint newValue);

    public static int Run(string[] args, bool useDdcci)
    {
        Options options = ParseOptions(args);
        DateTime stopAt = DateTime.UtcNow.AddSeconds(options.GuardSeconds);

        do
        {
            TurnMonitorsOff(useDdcci);

            TimeSpan remaining = stopAt - DateTime.UtcNow;
            if (remaining <= TimeSpan.Zero)
            {
                break;
            }

            int sleepMs = (int)Math.Min(TimeSpan.FromSeconds(options.IntervalSeconds).TotalMilliseconds, remaining.TotalMilliseconds);
            if (WaitForNextIntervalOrEscape(Math.Max(250, sleepMs)))
            {
                break;
            }
        }
        while (DateTime.UtcNow < stopAt);

        return 0;
    }

    private static Options ParseOptions(string[] args)
    {
        Options options = new Options();
        List<int> numbers = new List<int>();

        foreach (string arg in args)
        {
            int value;
            if (int.TryParse(arg, out value))
            {
                numbers.Add(value);
            }
        }

        if (numbers.Count > 0)
        {
            options.GuardSeconds = Clamp(numbers[0], 15, 1800);
        }

        if (numbers.Count > 1)
        {
            options.IntervalSeconds = Clamp(numbers[1], 1, 60);
        }

        return options;
    }

    private static int Clamp(int value, int min, int max)
    {
        if (value < min)
        {
            return min;
        }

        if (value > max)
        {
            return max;
        }

        return value;
    }

    private static void TurnMonitorsOff(bool useDdcci)
    {
        IntPtr unused;
        SendMessageTimeout(
            new IntPtr(HWND_BROADCAST),
            WM_SYSCOMMAND,
            new IntPtr(SC_MONITORPOWER),
            MONITOR_OFF,
            SendMessageTimeoutFlags.SMTO_ABORTIFHUNG,
            1000,
            out unused);

        if (useDdcci)
        {
            TurnPhysicalMonitorsOff();
        }
    }

    private static void TurnPhysicalMonitorsOff()
    {
        try
        {
            EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, SetPhysicalMonitorsLowPower, IntPtr.Zero);
        }
        catch
        {
            // DDC/CI support varies by monitor and driver. Keep the normal Windows path best-effort.
        }
    }

    private static bool SetPhysicalMonitorsLowPower(IntPtr monitor, IntPtr hdc, ref Rect rect, IntPtr data)
    {
        uint physicalMonitorCount;
        if (!GetNumberOfPhysicalMonitorsFromHMONITOR(monitor, out physicalMonitorCount) || physicalMonitorCount == 0)
        {
            return true;
        }

        PhysicalMonitor[] physicalMonitors = new PhysicalMonitor[physicalMonitorCount];
        if (!GetPhysicalMonitorsFromHMONITOR(monitor, physicalMonitorCount, physicalMonitors))
        {
            return true;
        }

        try
        {
            for (int i = 0; i < physicalMonitors.Length; i++)
            {
                if (physicalMonitors[i].Handle != IntPtr.Zero)
                {
                    SetVCPFeature(physicalMonitors[i].Handle, VCP_POWER_MODE, VCP_POWER_OFF_SOFT);
                }
            }
        }
        finally
        {
            DestroyPhysicalMonitors(physicalMonitorCount, physicalMonitors);
        }

        return true;
    }

    private static bool WaitForNextIntervalOrEscape(int sleepMs)
    {
        int remainingMs = sleepMs;

        while (remainingMs > 0)
        {
            if (WasEscapePressed())
            {
                return true;
            }

            int chunkMs = Math.Min(100, remainingMs);
            Thread.Sleep(chunkMs);
            remainingMs -= chunkMs;
        }

        return WasEscapePressed();
    }

    private static bool WasEscapePressed()
    {
        return (GetAsyncKeyState(VK_ESCAPE) & 0x8001) != 0;
    }
}
