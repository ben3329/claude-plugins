param([string]$Arg)

# Arg looks like:  claudefocus:claude-plugins
$token = $Arg -replace '^claudefocus:', ''
$token = [Uri]::UnescapeDataString($token).Trim()
if (-not $token) { exit 0 }

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class WinF {
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc cb, IntPtr l);
  public delegate bool EnumWindowsProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern void keybd_event(byte b, byte s, uint f, UIntPtr e);
  public static IntPtr Found = IntPtr.Zero;
  static string Needle;
  public static IntPtr Find(string needle){
    Needle = needle; Found = IntPtr.Zero;
    EnumWindows((h,l)=>{
      if(IsWindowVisible(h)){
        var sb=new StringBuilder(1024); GetWindowText(h,sb,1024); var t=sb.ToString();
        if(t.Contains("Visual Studio Code") && t.Contains(Needle)){ Found=h; return false; }
      }
      return true;
    }, IntPtr.Zero);
    return Found;
  }
  public static void Focus(IntPtr h){
    if(IsIconic(h)) ShowWindow(h, 9);            // SW_RESTORE
    keybd_event(0x12,0,0,UIntPtr.Zero);          // ALT down  (unlock SetForegroundWindow)
    keybd_event(0x12,0,2,UIntPtr.Zero);          // ALT up
    SetForegroundWindow(h);
  }
}
"@

$h = [WinF]::Find($token)
if ($h -ne [IntPtr]::Zero) { [WinF]::Focus($h) }
