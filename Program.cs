using System;
using System.Runtime.InteropServices;
using System.Threading;

internal static class Program
{
    private const int HWND_BROADCAST = 0xffff;
    private const int VK_ESCAPE = 0x1b;
    private const int WM_SYSCOMMAND = 0x0112;
    private const int SC_MONITORPOWER = 0xf170;
    private static readonly IntPtr MONITOR_OFF = new IntPtr(2);

    [Flags]
    private enum SendMessageTimeoutFlags : uint
    {
        SMTO_ABORTIFHUNG = 0x0002
    }

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

    private static int Main(string[] args)
    {
        int guardSeconds = ReadIntArg(args, 0, 180, 15, 1800);
        int intervalSeconds = ReadIntArg(args, 1, 4, 1, 60);
        DateTime stopAt = DateTime.UtcNow.AddSeconds(guardSeconds);

        do
        {
            TurnMonitorsOff();

            TimeSpan remaining = stopAt - DateTime.UtcNow;
            if (remaining <= TimeSpan.Zero)
            {
                break;
            }

            int sleepMs = (int)Math.Min(TimeSpan.FromSeconds(intervalSeconds).TotalMilliseconds, remaining.TotalMilliseconds);
            if (WaitForNextIntervalOrEscape(Math.Max(250, sleepMs)))
            {
                break;
            }
        }
        while (DateTime.UtcNow < stopAt);

        return 0;
    }

    private static int ReadIntArg(string[] args, int index, int defaultValue, int min, int max)
    {
        int value;
        if (args.Length <= index || !int.TryParse(args[index], out value))
        {
            return defaultValue;
        }

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

    private static void TurnMonitorsOff()
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
