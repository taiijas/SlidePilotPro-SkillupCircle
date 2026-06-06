using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace SlidePilotReceiver.Services;

public class InputInjector
{
    private const uint INPUT_MOUSE = 0;
    private const uint INPUT_KEYBOARD = 1;

    private const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
    private const uint KEYEVENTF_KEYUP = 0x0002;

    private const uint MOUSEEVENTF_MOVE = 0x0001;
    private const uint MOUSEEVENTF_LEFTDOWN = 0x0002;
    private const uint MOUSEEVENTF_LEFTUP = 0x0004;
    private const uint MOUSEEVENTF_RIGHTDOWN = 0x0008;
    private const uint MOUSEEVENTF_RIGHTUP = 0x0010;
    private const uint MOUSEEVENTF_MIDDLEDOWN = 0x0020;
    private const uint MOUSEEVENTF_MIDDLEUP = 0x0040;
    private const uint MOUSEEVENTF_WHEEL = 0x0800;

    [StructLayout(LayoutKind.Sequential)]
    private struct INPUT
    {
        public uint type;
        public InputUnion u;
    }

    [StructLayout(LayoutKind.Explicit)]
    private struct InputUnion
    {
        [FieldOffset(0)]
        public MOUSEINPUT mi;
        [FieldOffset(0)]
        public KEYBDINPUT ki;
        [FieldOffset(0)]
        public HARDWAREINPUT hi;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MOUSEINPUT
    {
        public int dx;
        public int dy;
        public int mouseData;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct KEYBDINPUT
    {
        public ushort wVk;
        public ushort wScan;
        public uint dwFlags;
        public uint time;
        public IntPtr dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct HARDWAREINPUT
    {
        public uint uMsg;
        public ushort wParamL;
        public ushort wParamH;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);

    private static readonly Dictionary<string, ushort> KeyMap = new(StringComparer.OrdinalIgnoreCase)
    {
        // Modifiers
        { "ctrl", 0x11 },
        { "control", 0x11 },
        { "alt", 0x12 },
        { "shift", 0x10 },
        { "win", 0x5B },
        { "lwin", 0x5B },

        // Arrows
        { "left", 0x25 },
        { "left_arrow", 0x25 },
        { "up", 0x26 },
        { "up_arrow", 0x26 },
        { "right", 0x27 },
        { "right_arrow", 0x27 },
        { "down", 0x28 },
        { "down_arrow", 0x28 },

        // Navigation
        { "page_up", 0x21 },
        { "page_down", 0x22 },
        { "space", 0x20 },
        { "escape", 0x1B },
        { "tab", 0x09 },

        // Function keys
        { "f5", 0x74 },

        // Letters
        { "a", 0x41 },
        { "b", 0x42 },
        { "c", 0x43 },
        { "d", 0x44 },
        { "l", 0x4C },
        { "r", 0x52 },
        { "w", 0x57 },
        { "0", 0x30 },

        // Symbols
        { "plus", 0xBB },
        { "minus", 0xBD },
        { "zero", 0x30 },

        // Presentation Actions
        { "next_slide", 0x27 },         // Right Arrow
        { "previous_slide", 0x25 },     // Left Arrow
        { "start_presentation", 0x74 }, // F5
        { "exit_presentation", 0x1B },  // Escape
        { "black_screen", 0x42 },       // B
        { "white_screen", 0x57 }        // W
    };

    private static bool IsExtendedKey(ushort vk)
    {
        return vk == 0x25 || vk == 0x26 || vk == 0x27 || vk == 0x28 || // Left, Up, Right, Down
               vk == 0x21 || vk == 0x22 || // Page Up, Page Down
               vk == 0x5B || vk == 0x5C;   // Win keys
    }

    public void SendKey(string keyName)
    {
        if (!KeyMap.TryGetValue(keyName, out ushort vk))
        {
            return;
        }

        uint dwFlagsDown = 0;
        uint dwFlagsUp = KEYEVENTF_KEYUP;

        if (IsExtendedKey(vk))
        {
            dwFlagsDown |= KEYEVENTF_EXTENDEDKEY;
            dwFlagsUp |= KEYEVENTF_EXTENDEDKEY;
        }

        INPUT[] inputs = new INPUT[2];
        inputs[0] = new INPUT { type = INPUT_KEYBOARD };
        inputs[0].u.ki.wVk = vk;
        inputs[0].u.ki.dwFlags = dwFlagsDown;

        inputs[1] = new INPUT { type = INPUT_KEYBOARD };
        inputs[1].u.ki.wVk = vk;
        inputs[1].u.ki.dwFlags = dwFlagsUp;

        SendInput(2, inputs, Marshal.SizeOf<INPUT>());
    }

    public void SendShortcut(List<string> keys)
    {
        if (keys == null || keys.Count == 0) return;

        List<ushort> vks = new List<ushort>();
        foreach (var keyName in keys)
        {
            if (KeyMap.TryGetValue(keyName, out ushort vk))
            {
                vks.Add(vk);
            }
        }

        if (vks.Count == 0) return;

        int inputCount = vks.Count * 2;
        INPUT[] inputs = new INPUT[inputCount];

        // Down events in order
        for (int i = 0; i < vks.Count; i++)
        {
            ushort vk = vks[i];
            uint dwFlags = 0;
            if (IsExtendedKey(vk)) dwFlags |= KEYEVENTF_EXTENDEDKEY;

            inputs[i] = new INPUT { type = INPUT_KEYBOARD };
            inputs[i].u.ki.wVk = vk;
            inputs[i].u.ki.dwFlags = dwFlags;
        }

        // Up events in reverse order
        for (int i = 0; i < vks.Count; i++)
        {
            ushort vk = vks[vks.Count - 1 - i];
            uint dwFlags = KEYEVENTF_KEYUP;
            if (IsExtendedKey(vk)) dwFlags |= KEYEVENTF_EXTENDEDKEY;

            inputs[vks.Count + i] = new INPUT { type = INPUT_KEYBOARD };
            inputs[vks.Count + i].u.ki.wVk = vk;
            inputs[vks.Count + i].u.ki.dwFlags = dwFlags;
        }

        SendInput((uint)inputCount, inputs, Marshal.SizeOf<INPUT>());
    }

    public void MouseMove(int dx, int dy)
    {
        INPUT input = new INPUT { type = INPUT_MOUSE };
        input.u.mi.dx = dx;
        input.u.mi.dy = dy;
        input.u.mi.dwFlags = MOUSEEVENTF_MOVE;
        SendInput(1, new[] { input }, Marshal.SizeOf<INPUT>());
    }

    public void MouseClick(string button)
    {
        INPUT[] inputs = new INPUT[2];
        inputs[0] = new INPUT { type = INPUT_MOUSE };
        inputs[0].u.mi.dwFlags = GetMouseDownFlag(button);

        inputs[1] = new INPUT { type = INPUT_MOUSE };
        inputs[1].u.mi.dwFlags = GetMouseUpFlag(button);

        SendInput(2, inputs, Marshal.SizeOf<INPUT>());
    }

    public void MouseButtonDown(string button)
    {
        INPUT input = new INPUT { type = INPUT_MOUSE };
        input.u.mi.dwFlags = GetMouseDownFlag(button);
        SendInput(1, new[] { input }, Marshal.SizeOf<INPUT>());
    }

    public void MouseButtonUp(string button)
    {
        INPUT input = new INPUT { type = INPUT_MOUSE };
        input.u.mi.dwFlags = GetMouseUpFlag(button);
        SendInput(1, new[] { input }, Marshal.SizeOf<INPUT>());
    }

    public void MouseScroll(int delta)
    {
        INPUT input = new INPUT { type = INPUT_MOUSE };
        input.u.mi.mouseData = delta;
        input.u.mi.dwFlags = MOUSEEVENTF_WHEEL;
        SendInput(1, new[] { input }, Marshal.SizeOf<INPUT>());
    }

    private uint GetMouseDownFlag(string button)
    {
        return button.ToLowerInvariant() switch
        {
            "left" => MOUSEEVENTF_LEFTDOWN,
            "right" => MOUSEEVENTF_RIGHTDOWN,
            "middle" => MOUSEEVENTF_MIDDLEDOWN,
            _ => 0
        };
    }

    private uint GetMouseUpFlag(string button)
    {
        return button.ToLowerInvariant() switch
        {
            "left" => MOUSEEVENTF_LEFTUP,
            "right" => MOUSEEVENTF_RIGHTUP,
            "middle" => MOUSEEVENTF_MIDDLEUP,
            _ => 0
        };
    }
}
