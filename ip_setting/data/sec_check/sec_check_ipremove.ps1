
######################################################################
#
# [FileName]
#    sec_check_ipremove.ps1
#
# [Title]
#    Securityチェックスクリプト(IP-Remove)
#
# [処理内容]
#    ①LSC、SEP、WSUS設定の有無をチェックし、ログに出力します
#    ②猶予期間内にLSC、SEPの設定を行わなかった場合、IPアドレスを削除します
#
#    <前提条件>
#    powershell -ExecutionPolicy remotesigned <PS1 File>として実行する
#
# [戻り値]
#    正常	なし
#    エラー	なし
#
######################################################################

#rev
#----------------------------------------------------------------------------------------------------
[string] $rev = "1.0"

[string] $current = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

[string] $intfile = "$current\sec_check.int"

[string] $interface = Get-Content $intfile -Encoding UTF8

#エラー非表示
#----------------------------------------------------------------------------------------------------
$ErrorActionPreference = "SilentlyContinue" 

#コンソール非表示
#----------------------------------------------------------------------------------------------------
powershell -windowstyle hidden -command exit

#メイン処理
#----------------------------------------------------------------------------------------------------
netsh int ipv4 set add $interface dhcp
netsh int ipv4 set dns $interface dhcp
netsh int ipv4 set wins $interface dhcp

exit 0
