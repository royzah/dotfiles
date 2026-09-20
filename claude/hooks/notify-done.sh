#!/usr/bin/env bash
# Stop hook - desktop notification when Claude finishes, so long tasks
# ping you while you're in another tmux window / workspace

msg="Done in ${PWD##*/}"

# WSL has no notify-send; raise a Windows toast. WinRT types need Windows
# PowerShell 5.1 (not pwsh 7), and WSLENV passes the text without quoting games.
if [[ -n ${WSL_DISTRO_NAME:-} ]] && command -v powershell.exe > /dev/null 2>&1; then
  # shellcheck disable=SC2016 # $-names are PowerShell's, expanded on the Windows side
  ps='
$null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
$xml = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
$text = $xml.GetElementsByTagName("text")
$null = $text.Item(0).AppendChild($xml.CreateTextNode("Claude Code"))
$null = $text.Item(1).AppendChild($xml.CreateTextNode($env:CC_NOTIFY_MSG))
$app = "{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe"
[Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($app).Show([Windows.UI.Notifications.ToastNotification]::new($xml))
'
  # Backgrounded: powershell.exe takes about a second to start, the hook should not
  (CC_NOTIFY_MSG="$msg" WSLENV="${WSLENV:+$WSLENV:}CC_NOTIFY_MSG" \
    powershell.exe -NoProfile -NonInteractive -Command "$ps" > /dev/null 2>&1 &)
  exit 0
fi

command -v notify-send > /dev/null 2>&1 || exit 0
notify-send -i dialog-information "Claude Code" "$msg" 2> /dev/null || true
exit 0
