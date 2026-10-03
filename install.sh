#!/usr/bin/env bash
# jt-ucsi18n — UCS (Univention Corporate Server) 繁體中文 (zh_TW) 語言套件安裝工具
#
#   安裝/更新:  curl -fsSL https://raw.githubusercontent.com/jasoncheng7115/jt-ucsi18n/main/install.sh | bash
#   其他指令:   jt-ucsi18n status | update | remove      (安裝後可用)
#   帶參數:     curl -fsSL .../install.sh | bash -s -- status
#
# 會自動偵測 UCS 版本 (ucr version/version + version/patchlevel),依 dist/versions.txt
# 選出對應的語言套件,驗證 SHA256 後以 dpkg 安裝。只新增 zh_TW 檔案,不修改 UCS 既有檔案。
set -euo pipefail

REPO="${JT_UCSI18N_REPO:-jasoncheng7115/jt-ucsi18n}"
BASE="${JT_UCSI18N_BASE:-https://raw.githubusercontent.com/$REPO/main}"
PKG=univention-l10n-zh-tw
STATE_DIR=/var/lib/jt-ucsi18n
SELF=/usr/local/sbin/jt-ucsi18n

FORCE=0
DO_LDAP=1
CMD=install

info() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[警告]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[錯誤]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
	cat <<EOF
用法: jt-ucsi18n [install|update|status|remove] [--force] [--no-ldap]

  install / update   偵測 UCS 版本,下載並安裝對應的繁體中文語言套件 (預設)
  status             顯示 UCS 版本、已安裝的語言套件與可用版本
  remove             移除語言套件並取消登入頁的繁體中文選項
  --force            UCS 版本不在支援清單時仍強制安裝最接近的套件
  --no-ldap          不寫入 LDAP 的顯示名稱翻譯 (入口網站項目、擴充屬性)
EOF
}

fetch() { # fetch <url> <dest>
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --retry 2 -o "$2" "$1"
	else
		wget -q -O "$2" "$1"
	fi
}

detect() {
	command -v ucr >/dev/null 2>&1 || die "找不到 ucr,這台主機不是 UCS。"
	UCS_SERIES="$(ucr get version/version)"
	UCS_PL="$(ucr get version/patchlevel)"
	UCS_ROLE="$(ucr get server/role)"
	[[ "$UCS_SERIES" =~ ^[0-9]+\.[0-9]+$ && "$UCS_PL" =~ ^[0-9]+$ ]] || die "無法判斷 UCS 版本 (version/version=$UCS_SERIES, patchlevel=$UCS_PL)。"
	UCS_VER="$UCS_SERIES-$UCS_PL"
}

installed_version() { dpkg-query -W -f='${Version}' "$PKG" 2>/dev/null || true; }

# 依 versions.txt 選出套件。欄位: 系列 最低patchlevel 最高patchlevel 套件版本 檔案 sha256
# 設定 SEL_VER SEL_FILE SEL_SHA SEL_MATCH (exact|newer|forced)
select_package() {
	local manifest="$1" line
	SEL_MATCH=""
	# 1) 版本落在支援範圍內
	line="$(awk -v s="$UCS_SERIES" -v p="$UCS_PL" '$1==s && p>=$2 && p<=$3 {print; exit}' "$manifest")"
	if [ -n "$line" ]; then
		SEL_MATCH=exact
	else
		# 2) 同系列但比支援的最高 patchlevel 還新 -> 用該系列最新的套件
		line="$(awk -v s="$UCS_SERIES" -v p="$UCS_PL" '$1==s && p>$3 {if ($3>m || m=="") {m=$3; l=$0}} END {print l}' "$manifest")"
		if [ -n "$line" ]; then
			SEL_MATCH=newer
		elif [ "$FORCE" = 1 ]; then
			# 3) --force: 取清單中最後一筆 (最新系列)
			line="$(awk '!/^#/ && NF>=6 {l=$0} END {print l}' "$manifest")"
			[ -n "$line" ] && SEL_MATCH=forced
		fi
	fi
	[ -n "$SEL_MATCH" ] || return 1
	read -r _ SEL_MIN SEL_MAX SEL_VER SEL_FILE SEL_SHA <<<"$line"
}

supported_list() { awk '!/^#/ && NF>=6 {printf "  UCS %s-%s ~ %s-%s (套件 %s)\n", $1,$2,$1,$3,$4}' "$1"; }

restart_services() {
	local s
	for s in univention-management-console-server univention-portal-server apache2; do
		if systemctl list-unit-files "$s.service" 2>/dev/null | grep -q "^$s"; then
			systemctl restart "$s" || warn "無法重新啟動 $s"
		fi
	done
}

# LDAP 內的多語顯示名稱 (不在 .po 內)。格式: UDM模組|相對DN|屬性|譯文
ldap_items() {
	cat <<'EOF'
portals/category|cn=domain-admin,cn=category,cn=portals,cn=univention|displayName|管理
portals/category|cn=local-admin,cn=category,cn=portals,cn=univention|displayName|管理
portals/category|cn=self-service-profile,cn=category,cn=portals,cn=univention|displayName|使用者設定檔
portals/category|cn=self-service-password,cn=category,cn=portals,cn=univention|displayName|密碼
portals/category|cn=self-service-new-account,cn=category,cn=portals,cn=univention|displayName|新增帳號
portals/entry|cn=umc-domain,cn=entry,cn=portals,cn=univention|displayName|系統與網域設定
portals/entry|cn=umc-local,cn=entry,cn=portals,cn=univention|displayName|系統設定
portals/entry|cn=self-service,cn=entry,cn=portals,cn=univention|displayName|變更密碼
portals/entry|cn=univentionblog,cn=entry,cn=portals,cn=univention|displayName|Univention 部落格
portals/entry|cn=univentionforum,cn=entry,cn=portals,cn=univention|displayName|Univention 論壇 (說明)
portals/entry|cn=univentionfeedback,cn=entry,cn=portals,cn=univention|displayName|意見回饋
portals/entry|cn=univentionwebsite,cn=entry,cn=portals,cn=univention|displayName|Univention 網站
portals/entry|cn=login-ucs,cn=entry,cn=portals,cn=univention|displayName|登入
portals/entry|cn=login-saml,cn=entry,cn=portals,cn=univention|displayName|登入 (單一登入)
portals/entry|cn=root-cert,cn=entry,cn=portals,cn=univention|displayName|根憑證
portals/entry|cn=certificate-revocation,cn=entry,cn=portals,cn=univention|displayName|憑證撤銷清單
portals/entry|cn=self-service-my-profile,cn=entry,cn=portals,cn=univention|displayName|我的設定檔
portals/entry|cn=self-service-protect-account,cn=entry,cn=portals,cn=univention|displayName|保護您的帳號
portals/entry|cn=self-service-password-forgotten,cn=entry,cn=portals,cn=univention|displayName|忘記密碼
portals/entry|cn=self-service-service-specific-passwords,cn=entry,cn=portals,cn=univention|displayName|無線區域網路密碼
portals/entry|cn=self-service-create-account,cn=entry,cn=portals,cn=univention|displayName|建立帳號
portals/entry|cn=self-service-verify-account,cn=entry,cn=portals,cn=univention|displayName|帳號驗證
portals/entry|cn=self-service-password-change,cn=entry,cn=portals,cn=univention|displayName|變更您的密碼
settings/extended_attribute|cn=UniventionPasswordSelfServiceEmail,cn=custom attributes,cn=univention|translationTabName|密碼復原
settings/extended_attribute|cn=UniventionPasswordSelfServiceEmail,cn=custom attributes,cn=univention|translationShortDescription|電子郵件地址
settings/extended_attribute|cn=UniventionPasswordSelfServiceMobile,cn=custom attributes,cn=univention|translationTabName|密碼復原
settings/extended_attribute|cn=UniventionPasswordSelfServiceMobile,cn=custom attributes,cn=univention|translationShortDescription|行動電話號碼
settings/extended_attribute|cn=UniventionPasswordRecoveryEmailVerified,cn=custom attributes,cn=univention|translationTabName|密碼復原
settings/extended_attribute|cn=UniventionPasswordRecoveryEmailVerified,cn=custom attributes,cn=univention|translationShortDescription|電子郵件地址已驗證
settings/extended_attribute|cn=UniventionRegisteredThroughSelfService,cn=custom attributes,cn=univention|translationTabName|密碼復原
settings/extended_attribute|cn=UniventionRegisteredThroughSelfService,cn=custom attributes,cn=univention|translationShortDescription|自助註冊
settings/extended_attribute|cn=UniventionDeregisteredThroughSelfService,cn=custom attributes,cn=univention|translationTabName|密碼復原
settings/extended_attribute|cn=UniventionDeregisteredThroughSelfService,cn=custom attributes,cn=univention|translationShortDescription|自助取消註冊
settings/extended_attribute|cn=UniventionDeregistrationTimestamp,cn=custom attributes,cn=univention|translationTabName|密碼復原
settings/extended_attribute|cn=UniventionDeregistrationTimestamp,cn=custom attributes,cn=univention|translationShortDescription|取消註冊時間戳記
settings/extended_attribute|cn=serviceprovider,cn=custom attributes,cn=univention|translationTabName|帳號
settings/extended_attribute|cn=serviceprovider,cn=custom attributes,cn=univention|translationShortDescription|為下列服務提供者啟用此使用者
settings/extended_attribute|cn=serviceprovider,cn=custom attributes,cn=univention|translationGroupName|SAML 設定
settings/extended_attribute|cn=serviceprovidergroup,cn=custom attributes,cn=univention|translationTabName|一般
settings/extended_attribute|cn=serviceprovidergroup,cn=custom attributes,cn=univention|translationShortDescription|為下列服務提供者啟用此群組
settings/extended_attribute|cn=serviceprovidergroup,cn=custom attributes,cn=univention|translationGroupName|SAML 設定
settings/extended_attribute|cn=ucs-monitoring,cn=custom attributes,cn=univention|translationTabName|警報
settings/extended_attribute|cn=ucs-monitoring,cn=custom attributes,cn=univention|translationShortDescription|已指派的監控警報
settings/extended_attribute|cn=objectFlag,cn=custom attributes,cn=univention|translationShortDescription|Univention 物件旗標
settings/extended_attribute|cn=lastbind,cn=custom attributes,cn=univention|translationShortDescription|上次成功登入的時間戳記
settings/extended_attribute|cn=portal,cn=custom attributes,cn=univention|translationTabName|入口網站
settings/extended_attribute|cn=portal,cn=custom attributes,cn=univention|translationShortDescription|入口網站
EOF
}

# 只在 Primary 執行 (LDAP 會複寫到其他節點);已有 zh_TW 值或物件不存在時略過,不覆蓋既有值。
apply_ldap() {
	[ "$UCS_ROLE" = domaincontroller_master ] || { info "非 Primary Directory Node,略過 LDAP 顯示名稱 (請在 Primary 上執行一次本工具)"; return 0; }
	command -v udm >/dev/null 2>&1 || return 0
	local base mod rdn attr val dn cur added=0 skipped=0
	base="$(ucr get ldap/base)"
	while IFS='|' read -r mod rdn attr val; do
		dn="$rdn,$base"
		cur="$(udm "$mod" list --position "$dn" 2>/dev/null || true)"
		if [ -z "$cur" ] || grep -q "^ *$attr: zh_TW:" <<<"$cur"; then
			skipped=$((skipped + 1))
			continue
		fi
		if udm "$mod" modify --dn "$dn" --append "$attr=\"zh_TW\" \"$val\"" >/dev/null 2>&1; then
			added=$((added + 1))
		else
			warn "LDAP 寫入失敗: $dn ($attr)"
		fi
	done < <(ldap_items)
	info "LDAP 顯示名稱: 新增 $added 筆,略過 $skipped 筆 (已存在或該物件未安裝)"
}

cmd_install() {
	detect
	local tmp manifest deb cur
	TMP_DIR="$(mktemp -d)"
	trap 'rm -rf "$TMP_DIR"' EXIT
	tmp="$TMP_DIR"
	manifest="$tmp/versions.txt"
	info "偵測到 UCS $UCS_VER ($UCS_ROLE)"
	fetch "$BASE/dist/versions.txt" "$manifest" || die "無法下載版本對應表: $BASE/dist/versions.txt"

	if ! select_package "$manifest"; then
		printf '目前支援的版本:\n%s\n' "$(supported_list "$manifest")" >&2
		die "UCS $UCS_VER 不在支援清單內。若仍要嘗試,請加上 --force。"
	fi
	case "$SEL_MATCH" in
		exact)  info "對應套件: $PKG $SEL_VER (適用 UCS $UCS_SERIES-$SEL_MIN ~ $UCS_SERIES-$SEL_MAX)" ;;
		newer)  warn "UCS $UCS_VER 比目前支援的 $UCS_SERIES-$SEL_MAX 新,先套用最新套件 $SEL_VER;新版才有的字串會顯示英文。之後執行 jt-ucsi18n update 可取得更新。" ;;
		forced) warn "UCS $UCS_VER 未經驗證,強制安裝套件 $SEL_VER (--force)。" ;;
	esac

	cur="$(installed_version)"
	if [ "$cur" = "$SEL_VER" ] && [ "$FORCE" = 0 ]; then
		info "已安裝 $PKG $cur,套件無需更新"
	else
		deb="$tmp/$(basename "$SEL_FILE")"
		info "下載 $SEL_FILE"
		fetch "$BASE/$SEL_FILE" "$deb" || die "下載失敗: $BASE/$SEL_FILE"
		echo "$SEL_SHA  $deb" | sha256sum -c --quiet - || die "SHA256 驗證失敗,已中止安裝。"
		info "安裝 $PKG $SEL_VER${cur:+ (取代 $cur)}"
		dpkg -i "$deb" >"$tmp/dpkg.log" 2>&1 || { cat "$tmp/dpkg.log" >&2; die "dpkg 安裝失敗。"; }
		locale -a 2>/dev/null | grep -qi '^zh_TW\.utf-\?8$' || locale-gen >/dev/null 2>&1 || warn "locale-gen 失敗"
		info "重新啟動 UMC / Portal / Apache"
		restart_services
	fi

	[ "$DO_LDAP" = 1 ] && apply_ldap

	mkdir -p "$STATE_DIR"
	printf 'ucs=%s\npackage=%s\nmatch=%s\ndate=%s\n' "$UCS_VER" "$SEL_VER" "$SEL_MATCH" "$(date -Is)" >"$STATE_DIR/state"
	# 把自己裝成指令,之後 UCS 升級完可直接執行 jt-ucsi18n update
	if fetch "$BASE/install.sh" "$tmp/self" && head -1 "$tmp/self" | grep -q '^#!'; then
		install -m 755 "$tmp/self" "$SELF"
	fi
	info "完成。請在登入頁語言選單選擇「Traditional Chinese」,並以 Ctrl+Shift+R 重新整理瀏覽器。"
}

cmd_status() {
	detect
	local cur tmp
	cur="$(installed_version)"
	echo "UCS 版本:       $UCS_VER ($UCS_ROLE)"
	echo "已安裝語言套件: ${cur:-未安裝}"
	if [ -f "$STATE_DIR/state" ]; then
		# shellcheck disable=SC1091
		. "$STATE_DIR/state"
		echo "上次套用:       UCS ${ucs:-?} / 套件 ${package:-?} / ${date:-?}"
		[ "${ucs:-}" = "$UCS_VER" ] || echo "  -> UCS 已從 ${ucs:-?} 升級到 $UCS_VER,建議執行: jt-ucsi18n update"
	fi
	tmp="$(mktemp)"
	if fetch "$BASE/dist/versions.txt" "$tmp" 2>/dev/null && select_package "$tmp"; then
		echo "可用套件:       $SEL_VER (對應方式: $SEL_MATCH)"
		[ "$cur" = "$SEL_VER" ] || echo "  -> 有不同版本可用,執行: jt-ucsi18n update"
	else
		echo "可用套件:       無 (UCS $UCS_VER 不在支援清單,或無法連線)"
	fi
	rm -f "$tmp"
}

cmd_remove() {
	detect
	if [ -n "$(installed_version)" ]; then
		info "移除 $PKG"
		dpkg -P "$PKG" >/dev/null
	fi
	ucr unset ucs/server/languages/zh_TW >/dev/null
	restart_services
	rm -rf "$STATE_DIR" "$SELF"
	info "已移除。系統 locale zh_TW.UTF-8 與 LDAP 內的 zh_TW 顯示名稱保留 (不影響其他語言)。"
}

main() {
	while [ $# -gt 0 ]; do
		case "$1" in
			install|update|status|remove) CMD="$1" ;;
			--force) FORCE=1 ;;
			--no-ldap) DO_LDAP=0 ;;
			-h|--help) usage; exit 0 ;;
			*) usage >&2; die "不認得的參數: $1" ;;
		esac
		shift
	done
	[ "$(id -u)" = 0 ] || die "請以 root 執行。"
	case "$CMD" in
		install|update) cmd_install ;;
		status) cmd_status ;;
		remove) cmd_remove ;;
	esac
}

main "$@"
