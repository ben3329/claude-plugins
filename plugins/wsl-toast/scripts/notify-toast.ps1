param(
  [string]$Title = "Claude Code",
  [string]$Message = "알림",
  [string]$Target = ""
)

[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType=WindowsRuntime] | Out-Null
[Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType=WindowsRuntime] | Out-Null

# Clicking the toast fires the claudefocus: protocol, which raises the matching VSCode window.
$launchAttr = ""
if ($Target) {
  $enc = [Uri]::EscapeDataString($Target)
  $launchAttr = " activationType=`"protocol`" launch=`"claudefocus:$enc`""
}

$xml = @"
<toast$launchAttr>
  <visual>
    <binding template="ToastText02">
      <text id="1">$([System.Security.SecurityElement]::Escape($Title))</text>
      <text id="2">$([System.Security.SecurityElement]::Escape($Message))</text>
    </binding>
  </visual>
</toast>
"@

$doc = New-Object Windows.Data.Xml.Dom.XmlDocument
$doc.LoadXml($xml)
$toast = [Windows.UI.Notifications.ToastNotification]::new($doc)
$appId = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
