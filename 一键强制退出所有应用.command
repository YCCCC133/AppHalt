#!/bin/zsh

case "${1:-}" in
  '') ;;
  --dry-run) ;;
  -h|--help) print -- '用法：一键强制退出所有应用.command [--dry-run]'; exit 0 ;;
  *) print -u2 -- "未知参数：$1"; exit 2 ;;
esac
(( $# <= 1 )) || { print -u2 -- '参数过多。'; exit 2; }


# 一键关闭所有访达窗口，并强制退出当前用户的所有前台、后台及菜单栏应用。
# 仅操作当前用户的进程，不使用 sudo，也不会要求输入密码。

set -u

app_list=$(/usr/bin/osascript -l JavaScript <<'JXA'
ObjC.import('AppKit');

$.NSWorkspace.sharedWorkspace.runningApplications.js
  .filter(function (app) {
    // 0 = 普通应用，1 = 后台/菜单栏应用；排除纯系统守护进程。
    return Number(app.activationPolicy) !== 2;
  })
  .map(function (app) {
    var name = ObjC.unwrap(app.localizedName) || '未命名应用';
    var bundleID = ObjC.unwrap(app.bundleIdentifier) || '';
    return Number(app.processIdentifier) + '\t' + bundleID + '\t' + name;
  })
  .join('\n');
JXA
)

if [[ -z "$app_list" ]]; then
  exit 0
fi

# 便于日后安全检查：终端执行“脚本路径 --dry-run”只显示目标。
if [[ "${1:-}" == "--dry-run" ]]; then
  print -r -- "$app_list"
  exit 0
fi

# 访达由系统自动重启，不能和普通应用一样强杀；否则可能恢复旧窗口。
# 将它排除，改由后台任务持续关闭窗口。
app_pids=$(print -r -- "$app_list" | /usr/bin/awk -F '\t' \
  '/^[0-9]+\t/ && $2 != "com.apple.finder" { print $1 }')
current_uid=$(/usr/bin/id -u)

# 脱离启动它的终端后再执行，因此“终端”自身也能被强制退出。
APP_PIDS="$app_pids" APP_UID="$current_uid" \
  /usr/bin/nohup /bin/zsh -c '
    trap "" HUP
    /bin/sleep 0.1

    for pid in ${(f)APP_PIDS}; do
      [[ "$pid" == <-> ]] || continue

      owner_uid=$(/bin/ps -p "$pid" -o uid= 2>/dev/null)
      owner_uid="${owner_uid//[[:space:]]/}"
      [[ "$owner_uid" == "$APP_UID" ]] || continue

      /bin/kill -KILL "$pid" 2>/dev/null
    done

    # 连续处理访达可能正在打开或动画中的窗口，直到全部消失。
    for attempt in {1..10}; do
      remaining=$(/usr/bin/osascript \
        -e '\''tell application "Finder"'\'' \
        -e '\''try'\'' \
        -e '\''close every window'\'' \
        -e '\''end try'\'' \
        -e '\''return count of windows'\'' \
        -e '\''end tell'\'' 2>/dev/null)
      [[ "${remaining//[[:space:]]/}" == "0" ]] && break
      /bin/sleep 0.1
    done
  ' </dev/null >/dev/null 2>&1 &!

exit 0
