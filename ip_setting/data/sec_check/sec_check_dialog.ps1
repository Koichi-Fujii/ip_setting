
######################################################################
#
# [FileName]
#    sec_check_dialog.ps1
#
# [Title]
#    Securityチェックスクリプト(Dialog)
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
[string] $rev = "1.1"

[string] $current = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

[string] $intfile = "$current\sec_check.int"

[string] $interface = Get-Content $intfile -Encoding UTF8

[string] $logfile = "$current\sec_check_$env:computername.csv"
[string] $srv = "server"
[string] $srvlogdir = "\\$srv\logs$\SecurityCheckScript\clients"
[string] $srvlogfile = "\\$srv\logs$\SecurityCheckScript\all.csv"

[string] $a1 = [System.Text.Encoding]::Default.GetString([System.Convert]::FromBase64String("username"))
[string] $a2 = [System.Text.Encoding]::Default.GetString([System.Convert]::FromBase64String("password"))

[int] $congraceday = 10

[string] $xmltemplate = @"
<?xml version='1.0'?>
<config>
  <grace></grace>
  <lsc></lsc>
  <sep></sep>
  <wsus></wsus>
  <comment></comment>
  <upload></upload>
  <ver></ver>
</config>
"@

#エラー非表示
#----------------------------------------------------------------------------------------------------
$ErrorActionPreference = "SilentlyContinue" 

#コンソール非表示
#----------------------------------------------------------------------------------------------------
powershell -windowstyle hidden -command exit

#Assembly読み込み
#----------------------------------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Net
Add-Type -AssemblyName Microsoft.VisualBasic

#Fnc:Get-WSUS
#----------------------------------------------------------------------------------------------------
function Get-WSUS()
{
    $arr = (Get-ItemProperty -Path "HKLM:SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate").WUServer
    if($arr -eq $null){
        return "NG"
    }else{
        return "OK"
    }
}

#Fnc:Get-ItemValue
#----------------------------------------------------------------------------------------------------
function Get-ItemValue([string] $key,[string] $value)
{
    $native = "SOFTWARE\$key"
    $wow64 = "SOFTWARE\Wow6432Node\$key"
    $arr = (Get-Item -Path "HKLM:$native","HKLM:$wow64").GetValue($value)
    if($arr -eq $null){
        $arr = (Get-Item -Path "HKLM:$native").GetValue($value)
        if($arr -eq $null){
            return $null
        }else{
            return $arr
        }
    }else{
        return $arr
    }
}

#Fnc:Get-Install
#----------------------------------------------------------------------------------------------------
function Get-Install([string] $displayname)
{
    $native = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $wow64 = "SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    $arr = Get-ChildItem -Path("HKLM:$native","HKLM:$wow64","HKCU:$native") | %{Get-ItemProperty $_.PsPath} | ?{$_.DisplayName -eq "$displayname"}
    if($arr -eq $null){
        return "NG"
    }else{
        return "OK"
    }
}

#Fnc:Get-InstallLog
#----------------------------------------------------------------------------------------------------
function Get-InstallLog([string] $installlog)
{
    try{
        #$arr = (Get-Content -Path $installlog -Tail 1).Split(" ")
        #[datetime]$date = $arr[0]
        $arr = (Get-Content -Path $installlog -Encoding UTF8 -Delimiter " ")
        [datetime]$date = $arr[0].Replace("--","")
        return $date.ToShortDateString()
    }catch{
        return $null
    }
}

#Fnc:Btn-Click
#----------------------------------------------------------------------------------------------------
function Btn-Click()
{
    if($txt5.Enabled -eq $true -and $txt5.Text -eq ""){
        [Microsoft.VisualBasic.Interaction]::MsgBox("理由を入力してください","OKOnly,SystemModal,Exclamation","警告")


    }else{
        $frm1.Close()
    }
}

#Fnc:Write-Log
#----------------------------------------------------------------------------------------------------
function Write-Log([string] $strcol,[boolean] $bolsrv)
{
    $now = get-date -format "yyyy/MM/dd HH:mm:ss"
    $ipaddr = (Get-NetIPAddress -InterfaceAlias "$interface" -SuffixOrigin "Manual").IPAddress
    if($bolsrv){
        write-output "$now,$env:computername,$ipaddr,$strcol" | out-file -encoding default -filepath $srvlogfile -append
    }else{
        write-output "$now,$env:computername,$ipaddr,$strcol" | out-file -encoding default -filepath $logfile -append
    }
}

#フォームオブジェクト定義
#----------------------------------------------------------------------------------------------------
$frm1 = New-Object System.Windows.Forms.Form
$frm1.Font = New-Object System.Drawing.Font("メイリオ",12)
$frm1.Size = New-Object System.Drawing.Size(420,470)
$frm1.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$frm1.Text = "警告"
$frm1.TopMost = $true
$frm1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$frm1.MaximizeBox = $false
$frm1.ControlBox = $false
$frm1.ShowInTaskbar = $false

$pnl1 = New-Object System.Windows.Forms.Panel
$pnl1.Location = New-Object System.Drawing.Point(0,0)
$pnl1.Size = New-Object System.Drawing.Size(405,70)
$pnl1.BackColor = [System.Drawing.Color]::White

$pnl2 = New-Object System.Windows.Forms.Panel
$pnl2.Location = New-Object System.Drawing.Point(5,75)
$pnl2.Size = New-Object System.Drawing.Size(392,50)
$pnl2.BackColor = [System.Drawing.Color]::Yellow

$lbl0 = New-Object System.Windows.Forms.Label
$lbl0.Location = New-Object System.Drawing.Point(10,10)
$lbl0.Font = New-Object System.Drawing.Font("メイリオ",12,[System.Drawing.FontStyle]::Bold)
$lbl0.AutoSize = $true
$lbl0.Text = "以下のセキュリティー対策が実施されていません"
$lbl0.BackColor = [System.Drawing.Color]::Transparent

$lbl1 = New-Object System.Windows.Forms.Label
$lbl1.Location = New-Object System.Drawing.Point(10,38)
$lbl1.Font = New-Object System.Drawing.Font("メイリオ",12,[System.Drawing.FontStyle]::Bold)
$lbl1.AutoSize = $true
$lbl1.Text = "確認して実施してください"
$lbl1.BackColor = [System.Drawing.Color]::Transparent

$lbl2 = New-Object System.Windows.Forms.Label
$lbl2.Location = New-Object System.Drawing.Point(20,(100 + (35 * 1)))
$lbl2.AutoSize = $true
$lbl2.Text = "[資産管理]：LanScope"

$lbl3 = New-Object System.Windows.Forms.Label
$lbl3.Location = New-Object System.Drawing.Point(20,(100 + (35 * 2)))
$lbl3.AutoSize = $true
$lbl3.Text = "[ウイルス対策]：SEP"

$lbl4 = New-Object System.Windows.Forms.Label
$lbl4.Location = New-Object System.Drawing.Point(20,(100 + (35 * 3)))
$lbl4.AutoSize = $true
$lbl4.Text = "[セキュリティパッチ]：WSUS"

$lbl5 = New-Object System.Windows.Forms.Label
$lbl5.Location = New-Object System.Drawing.Point(20,(110 + (35 * 4)))
$lbl5.Font = New-Object System.Drawing.Font("メイリオ",9)
$lbl5.AutoSize = $true
$lbl5.Text = "WSUS対策されていない理由を記入してください"

$lbl6 = New-Object System.Windows.Forms.Label
$lbl6.Location = New-Object System.Drawing.Point(0,(120 + (35 * 7)))
$lbl6.Size = New-Object System.Drawing.Size(420,2)
$lbl6.BorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D

$lbl7 = New-Object System.Windows.Forms.Label
$lbl7.Location = New-Object System.Drawing.Point(5,5)
$lbl7.Font = New-Object System.Drawing.Font("メイリオ",9)
$lbl7.Size = New-Object System.Drawing.Size(220,50)
$lbl7.Text = "猶予期間内に対策が実施されない場合ネットワークから切断されます"

$lbl8 = New-Object System.Windows.Forms.Label
$lbl8.Location = New-Object System.Drawing.Point(230,5)
$lbl8.Font = New-Object System.Drawing.Font("メイリオ",11,[System.Drawing.FontStyle]::Bold)
$lbl8.Size = New-Object System.Drawing.Size(70,50)
$lbl8.Text = "切断まであと"

$lbl9 = New-Object System.Windows.Forms.Label
$lbl9.Location = New-Object System.Drawing.Point(300,5)
$lbl9.Font = New-Object System.Drawing.Font("メイリオ",20,[System.Drawing.FontStyle]::Bold)
$lbl9.Size = New-Object System.Drawing.Size(60,50)
$lbl9.Text = "7"
$lbl9.ForeColor = [System.Drawing.Color]::Red
$lbl9.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center

$lbl10 = New-Object System.Windows.Forms.Label
$lbl10.Location = New-Object System.Drawing.Point(360,28)
$lbl10.Font = New-Object System.Drawing.Font("メイリオ",11,[System.Drawing.FontStyle]::Bold)
$lbl10.Size = New-Object System.Drawing.Size(20,20)
$lbl10.Text = "日"

$txt2 = New-Object System.Windows.Forms.TextBox
$txt2.Location = New-Object System.Drawing.Point(300,(100 + (35 * 1)))
$txt2.Font = New-Object System.Drawing.Font("メイリオ",12,[System.Drawing.FontStyle]::Bold)
$txt2.Size = New-Object System.Drawing.Size(60,20)
$txt2.ReadOnly = $true
$txt2.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center

$txt3 = New-Object System.Windows.Forms.TextBox
$txt3.Location = New-Object System.Drawing.Point(300,(100 + (35 * 2)))
$txt3.Font = New-Object System.Drawing.Font("メイリオ",12,[System.Drawing.FontStyle]::Bold)
$txt3.Size = New-Object System.Drawing.Size(60,20)
$txt3.ReadOnly = $true
$txt3.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center

$txt4 = New-Object System.Windows.Forms.TextBox
$txt4.Location = New-Object System.Drawing.Point(300,(100 + (35 * 3)))
$txt4.Font = New-Object System.Drawing.Font("メイリオ",12,[System.Drawing.FontStyle]::Bold)
$txt4.Size = New-Object System.Drawing.Size(60,20)
$txt4.ReadOnly = $true
$txt4.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center

$txt5 = New-Object System.Windows.Forms.TextBox
$txt5.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical
$txt5.Multiline = $true
$txt5.Location = New-Object System.Drawing.Point(20,(135 + (35 * 4)))
$txt5.Font = New-Object System.Drawing.Font("メイリオ",9)
$txt5.Size = New-Object System.Drawing.Size(370,80)
$txt5.ImeMode = [System.Windows.Forms.ImeMode]::On

$chk1 = New-Object System.Windows.Forms.CheckBox
$chk1.Location = New-Object System.Drawing.Point(20,(165 + (35 * 6)))
$chk1.AutoSize = $true
$chk1.Text = "はい、確認して対策を実施します"
$chk1.Add_Click({$btn1.Enabled = $chk1.Checked})

$erp1 = New-Object System.Windows.Forms.ErrorProvider

$btn1 = New-Object System.Windows.Forms.Button
$btn1.Location = New-Object System.Drawing.Point(320,375)
$btn1.Size = New-Object System.Drawing.Size(75,35)
$btn1.Text = "確認"
$btn1.Add_Click({Btn-Click})
$btn1.Enabled = $false

$frm1.Controls.Add($pnl1)
$frm1.Controls.Add($pnl2)
$pnl1.Controls.Add($lbl0)
$pnl1.Controls.Add($lbl1)
$pnl2.Controls.Add($lbl7)
$pnl2.Controls.Add($lbl8)
$pnl2.Controls.Add($lbl9)
$pnl2.Controls.Add($lbl10)

$frm1.Controls.Add($btn1)
$frm1.Controls.Add($lbl2)
$frm1.Controls.Add($lbl3)
$frm1.Controls.Add($lbl4)
$frm1.Controls.Add($lbl5)
$frm1.Controls.Add($lbl6)
$frm1.Controls.Add($txt2)
$frm1.Controls.Add($txt3)
$frm1.Controls.Add($txt4)
$frm1.Controls.Add($txt5)
$frm1.Controls.Add($chk1)
$frm1.ActiveControl = $chk1

#メイン処理
#----------------------------------------------------------------------------------------------------

#ステータス取得
try{
    [xml]$xmlfile = Get-Content "$current\sec_check.status" -Encoding UTF8
    $xmlstatus = @($xmlfile.config.lsc,$xmlfile.config.sep,$xmlfile.config.wsus)
    $comment = $xmlfile.config.comment
    $upload = $xmlfile.config.upload
    [datetime]$grace = $xmlfile.config.grace
    $graceday = $grace - (get-date).AddDays(-1)
    $xmlver = $xmlfile.config.ver
}catch{
    [xml]$xmlfile = $xmltemplate
    $xmlstatus = @($xmlfile.config.lsc,$xmlfile.config.sep,$xmlfile.config.wsus)
    $comment = $xmlfile.config.comment
    $upload = $xmlfile.config.upload
    [datetime]$grace = (get-date).AddDays($congraceday)
    $graceday = $grace - (get-date).AddDays(-1)
    $xmlver = $xmlfile.config.ver
}

#現在値取得
#サーバーOSはLSCがNGでもOK
if((Get-WmiObject Win32_OperatingSystem).Caption -like "*Microsoft Windows Server*"){
    if(Get-Install("LanScope Cat MR") -eq "NG"){
        $LSCstatus = "対象外"
    }
}else{
    $LSCstatus = Get-Install("LanScope Cat MR")
}

$status = @(($LSCstatus),(Get-Install("Symantec Endpoint Protection")),(Get-WSUS))
$status2 = @((Get-InstallLog("C:\ProgramData\MOTEX\MR\MrInst_Mr_Utf8.log")),(Get-ItemValue "MOTEX\LanScope Cat MR\CurrentVersion\InvInfo\Data\Inventory" "MrVersion"),(Get-InstallLog("C:\ProgramData\Symantec\Symantec Endpoint Protection\CurrentVersion\Data\Install\Logs\SIS_INST.LOG")),(Get-ItemValue "Symantec\Symantec Endpoint Protection\CurrentVersion" "PRODUCTVERSION"))
$ver = (Get-ItemValue "MOTEX\LanScope Cat MR\CurrentVersion\InvInfo\Data\Inventory" "MrVersion")+","+(Get-ItemValue "Symantec\Symantec Endpoint Protection\CurrentVersion" "PRODUCTVERSION")

#比較用に整形
$status0 = $status[0]+","+$status[1]
$xmlstatus0 = $xmlstatus[0]+","+$xmlstatus[1]

#残日数表示
$lbl9.Text = $graceday.Days

#ステータス表示
$txt2.Text = $status[0]
$txt3.Text = $status[1]
$txt4.Text = $status[2]
$txt5.Text = $comment

#ステータス比較
if($status0 -notlike "*NG*"){
    if($status[2] -eq "NG" -and $comment -eq ""){
        $dlgflg = $false
    }else{
        $dlgflg = $true
    }
}else{
    #IP削除フラグ
    if($graceday.Days -le 0){
        Remove-Item -Path "$current\sec_check.status"
        Write-EventLog -LogName Application -EntryType Information -Source Application -EventId 65535 -Message "."
        [Microsoft.VisualBasic.Interaction]::MsgBox("ネットワークから切断するために、IPアドレスを削除しました","OKOnly,SystemModal,Exclamation","警告")


        $frm1.Close()
        exit 0
    }
    $dlgflg = $false
}

#ステータス色分け
if($txt2.Text -eq "OK"){
    $txt2.BackColor = [System.Drawing.Color]::Lime    
}else{
    $txt2.BackColor = [System.Drawing.Color]::Red
}

if($txt3.Text -eq "OK"){
    $txt3.BackColor = [System.Drawing.Color]::Lime
}else{
    $txt3.BackColor = [System.Drawing.Color]::Red
}

if($txt4.Text -eq "OK"){
    $txt4.BackColor = [System.Drawing.Color]::Lime
    $txt5.Enabled = $false
}else{
    $txt4.BackColor = [System.Drawing.Color]::Red
}

#正常時はフォーム表示しない
if($dlgflg){
    $xmlfile.config.grace = (get-date).AddDays($congraceday).ToShortDateString()
}else{
    $frm1.ShowDialog()
    $xmlfile.config.grace = $grace.ToShortDateString()
}

#ステータス出力
$xmlfile.config.lsc = $status[0].ToString()
$xmlfile.config.sep = $status[1].ToString()
$xmlfile.config.wsus = $status[2].ToString()
$xmlfile.config.comment = $txt5.Text
$xmlfile.config.ver = $ver
$xmlfile.Save("$current\sec_check.status")

net use "$srvlogdir" $a2 /user:"$srv\$a1" /persistent:no

#ログ出力/ログアップロード
if($status0 -ne $xmlstatus0 -or $status[2] -ne $xmlstatus[2] -or $comment -ne $txt5.Text -or $ver -ne $xmlver){
    $comment = @($txt5.Text)
    $status1 = ($status+$comment+$status2) -join ","
    Write-Log "$status1" $false
    Write-Log "$status1" $true
    $upload = $false
    $xmlfile.Save("$current\sec_check.status")
}

#アップロードステータスがTrue以外はアップロード処理
if($upload -ne $true){
    copy "$logfile" "$srvlogdir"
    $xmlfile.config.upload = $?.ToString()
    $xmlfile.Save("$current\sec_check.status")
}

exit 0
