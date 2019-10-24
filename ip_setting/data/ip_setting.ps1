
######################################################################
#
# [FileName]
#    ip_setting.ps1
#
# [Title]
#    IPアドレス設定スクリプト
#
# [処理内容]
#    ①IP、DNS、WINSアドレスを設定します
#    ②Securityチェックスクリプトを設定します
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
[string] $datadir = "$current"

[string] $intfile = "C:\Program Files\SupportTools\Tools\sec_check\sec_check.int"
[string] $intdir  = "C:\Program Files\SupportTools\Tools\sec_check"

#DNS/WINS定義
#----------------------------------------------------------------------------------------------------
$dns0 = @("1.○○に設置","2.○○に設置","3.○○に設置")
$dns1 = @("XXX.XXX.XXX.XXX","XXX.XXX.XXX.XXX","XXX.XXX.XXX.XXX")
$dns2 = @("XXX.XXX.XXX.XXX","XXX.XXX.XXX.XXX","XXX.XXX.XXX.XXX")
$dns3 = @("XXX.XXX.XXX.XXX","XXX.XXX.XXX.XXX","XXX.XXX.XXX.XXX")

$wins0 = @("1.○○")
$wins1 = @("XXX.XXX.XXX.XXX","XXX.XXX.XXX.XXX")

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
#----------------------------------------------------------------------------------------------------

#Fnc:Convert-IpAddressToMaskLength
#----------------------------------------------------------------------------------------------------
#function Convert-IpAddressToMaskLength([string] $dottedIpAddressString)
#{
#    $result = 0
#    [IPAddress] $ip = $dottedIpAddressString
#    $octets = $ip.IPAddressToString.Split('.')
#    foreach($octet in $octets){
#        while(0 -ne $octet){
#            $octet = ($octet -shl 1) -band [byte]::MaxValue
#            $result++
#        }
#    }
#    return $result
#}

#Fnc:IP-Set
#----------------------------------------------------------------------------------------------------
function IP-Set()
{
    $erp1.SetError($lbl1,$null)
    $erp1.SetError($txt1,$null)
    $erp1.SetError($txt2,$null)
    $erp1.SetError($txt3,$null)
    try{
        [IPAddress] $ipaddr = $txt1.Text
    }catch{
        $erp1.SetError($txt1,"無効な IP アドレスが指定されました。")
    }
    try{
        [IPAddress] $subnet = $txt2.Text
#        [String] $subnetbit = Convert-IpAddressToMaskLength($subnet)
    }catch{
        $erp1.SetError($txt2,"無効な IP アドレスが指定されました。")
    }
    try{
        [IPAddress] $gateway = $txt3.Text
    }catch{
        $erp1.SetError($txt3,"無効な IP アドレスが指定されました。")
    }
    if($ipaddr -ne $null -and $subnet -ne $null -and $gateway -ne $null){
        try{
            #IP処理
            netsh int ipv4 set add $drp3.SelectedItem static $ipaddr.ToString() $subnet.ToString() $gateway.ToString() 1
            if($? -eq $false){
                $lbl1.Text = "IP設定に失敗しました"
                $erp1.SetError($lbl1.Text)
                return
            }
            #DNS処理
            $i = 0
            switch($drp1.SelectedIndex){
                0{
                    $dns = $dns1
                }
                1{
                    $dns = $dns2
                }
                2{
                    $dns = $dns3
                }
            }
            netsh int ipv4 set dns $drp3.SelectedItem dhcp
            foreach ($tmp in $dns){
                $i += 1
                netsh int ipv4 add dns $drp3.SelectedItem $tmp $i
                if($? -eq $false){
                    $lbl1.Text = "DNS設定に失敗しました"
                    $erp1.SetError($lbl1.Text)
                    return
                }
            }
            #WINS処理
            $i = 0
            switch($drp2.SelectedIndex){
                0{
                    $wins = $wins1
                }
            }
            netsh int ipv4 set wins $drp3.SelectedItem dhcp
            foreach ($tmp in $wins){
                $i += 1
                netsh int ipv4 add wins $drp3.SelectedItem $tmp $i
                if($? -eq $false){
                    $lbl1.Text = "WINS設定に失敗しました"
                    $erp1.SetError($lbl1.Text)
                    return
                }
            }
            #ファイルコピー
            xcopy /e /i /y "$datadir\sec_check" "$env:ProgramFiles\SupportTools\Tools\sec_check"
            if($? -eq $false){
                $lbl1.Text = "ファイルコピーに失敗しました"
                $erp1.SetError($lbl1.Text)
                return
            }
            #タスク登録処理1
            schtasks /create /tn "sec_check_dialog" /xml "$datadir\sec_check_dialog.xml" /f
            if($? -eq $false){
                $lbl1.Text = "タスク登録1に失敗しました"
                $erp1.SetError($lbl1.Text)
                return
            }
            #タスク登録処理2
            schtasks /create /tn "sec_check_ipremove" /xml "$datadir\sec_check_ipremove.xml" /f
            if($? -eq $false){
                $lbl1.Text = "タスク登録2に失敗しました"
                $erp1.SetError($lbl1.Text)
                return
            }
            #インターフェイスを記録
            write-output $drp3.SelectedItem | out-file -Encoding UTF8 -FilePath $intfile
            #Everyone書込権限を付与
            icacls $intdir /grant everyone:rw
            #完了メッセージ表示
            [Microsoft.VisualBasic.Interaction]::MsgBox("IPアドレスを設定しました","OKOnly,SystemModal,Information","情報")


            $frm1.Close()
        }catch{
            $lbl1.Text = $error[0].ToString()
            $erp1.SetError($lbl1,$error[0].ToString())
        }
    }
}

#Fnc:Btn-Click
#----------------------------------------------------------------------------------------------------
function Btn-Click()
{
    IP-Set
}

#Fnc:Write-Log
#----------------------------------------------------------------------------------------------------
function Write-Log([string] $strcol)
{
    $now = get-date -format "yyyy/MM/dd HH:mm:ss"
    write-output "[$now]`t$strcol" | out-file -encoding default -filepath $logfile -append
}

#フォームオブジェクト定義
#----------------------------------------------------------------------------------------------------
$frm1 = New-Object System.Windows.Forms.Form
$frm1.Font = New-Object System.Drawing.Font("メイリオ",12)
$frm1.Size = New-Object System.Drawing.Size(420,400)
$frm1.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$frm1.Text = "IP設定ツール"
$frm1.TopMost = $true
$frm1.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$frm1.MaximizeBox = $false
$frm1.ControlBox = $false
$frm1.ShowInTaskbar = $false

$pnl1 = New-Object System.Windows.Forms.Panel
$pnl1.Location = New-Object System.Drawing.Point(0,0)
$pnl1.Size = New-Object System.Drawing.Size(420,70)
$pnl1.BackColor = [System.Drawing.Color]::White

$lbl0 = New-Object System.Windows.Forms.Label
$lbl0.Location = New-Object System.Drawing.Point(10,10)
$lbl0.Font = New-Object System.Drawing.Font("メイリオ",12,[System.Drawing.FontStyle]::Bold)
$lbl0.AutoSize = $true
$lbl0.Text = "設定するIPアドレスを入力してください"
$lbl0.BackColor = [System.Drawing.Color]::Transparent

$lbl1 = New-Object System.Windows.Forms.Label
$lbl1.Location = New-Object System.Drawing.Point(10,38)
$lbl1.Font = New-Object System.Drawing.Font("メイリオ",9)
$lbl1.Size = New-Object System.Drawing.Size(370,40)
$lbl1.BackColor = [System.Drawing.Color]::Transparent
$lbl1.ForeColor = [System.Drawing.Color]::Red

$lbl2 = New-Object System.Windows.Forms.Label
$lbl2.Location = New-Object System.Drawing.Point(10,(80 + (35 * 0)))
$lbl2.AutoSize = $true
$lbl2.Text = "IPアドレス:"

$lbl3 = New-Object System.Windows.Forms.Label
$lbl3.Location = New-Object System.Drawing.Point(10,(80 + (35 * 1)))
$lbl3.AutoSize = $true
$lbl3.Text = "サブネットマスク:"

$lbl4 = New-Object System.Windows.Forms.Label
$lbl4.Location = New-Object System.Drawing.Point(10,(80 + (35 * 2)))
$lbl4.AutoSize = $true
$lbl4.Text = "ゲートウェイ:"

$lbl5 = New-Object System.Windows.Forms.Label
$lbl5.Location = New-Object System.Drawing.Point(10,(80 + (35 * 3)))
$lbl5.AutoSize = $true
$lbl5.Text = "DNS:"

$lbl6 = New-Object System.Windows.Forms.Label
$lbl6.Location = New-Object System.Drawing.Point(10,(80 + (35 * 4)))
$lbl6.AutoSize = $true
$lbl6.Text = "WINS:"

$lbl7 = New-Object System.Windows.Forms.Label
$lbl7.Location = New-Object System.Drawing.Point(10,(80 + (35 * 5)))
$lbl7.AutoSize = $true
$lbl7.Text = "インターフェイス:"

$lbl8 = New-Object System.Windows.Forms.Label
$lbl8.Location = New-Object System.Drawing.Point(0,(130 + (35 * 5)))
$lbl8.Size = New-Object System.Drawing.Size(420,2)
$lbl8.BorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D

$txt1 = New-Object System.Windows.Forms.TextBox
$txt1.Location = New-Object System.Drawing.Point(180,(80 + (35 * 0)))
$txt1.Size = New-Object System.Drawing.Size(200,20)
$txt1.ImeMode = [System.Windows.Forms.ImeMode]::Disable
$txt1.MaxLength = 15

$txt2 = New-Object System.Windows.Forms.TextBox
$txt2.Location = New-Object System.Drawing.Point(180,(80 + (35 * 1)))
$txt2.Size = New-Object System.Drawing.Size(200,20)
$txt2.ImeMode = [System.Windows.Forms.ImeMode]::Disable
$txt2.MaxLength = 15

$txt3 = New-Object System.Windows.Forms.TextBox
$txt3.Location = New-Object System.Drawing.Point(180,(80 + (35 * 2)))
$txt3.Size = New-Object System.Drawing.Size(200,20)
$txt3.ImeMode = [System.Windows.Forms.ImeMode]::Disable
$txt3.MaxLength = 15

$erp1 = New-Object System.Windows.Forms.ErrorProvider

$btn1 = New-Object System.Windows.Forms.Button
$btn1.Location = New-Object System.Drawing.Point(220,320)
$btn1.Size = New-Object System.Drawing.Size(75,35)
$btn1.Text = "OK"
$btn1.Add_Click({Btn-Click})

$btn2 = New-Object System.Windows.Forms.Button
$btn2.Location = New-Object System.Drawing.Point(310,320)
$btn2.Size = New-Object System.Drawing.Size(75,35)
$btn2.Text = "Cancel"
#$btn2.DialogResult = "Cancel"

$drp1 = New-Object System.Windows.Forms.ComboBox
$drp1.Location = New-Object System.Drawing.Point(180,(80 + (35 * 3)))
$drp1.Size = New-Object System.Drawing.Size(200,20)
$drp1.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

$dns0 | %{$drp1.Items.Add($_)} | Out-Null
$drp1.SelectedIndex = 0

$drp2 = New-Object System.Windows.Forms.ComboBox
$drp2.Location = New-Object System.Drawing.Point(180,(80 + (35 * 4)))
$drp2.Size = New-Object System.Drawing.Size(200,20)
$drp2.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

$wins0 | %{$drp2.Items.Add($_)} | Out-Null
$drp2.SelectedIndex = 0

$drp3 = New-Object System.Windows.Forms.ComboBox
$drp3.Location = New-Object System.Drawing.Point(180,(80 + (35 * 5)))
$drp3.Size = New-Object System.Drawing.Size(200,20)
$drp3.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList

#Get-NetAdapter -Physical | %{$drp3.Items.Add($_.Name)} | Out-Null
Get-WmiObject Win32_NetworkAdapter | ?{$_.PhysicalAdapter -eq $True} | %{$drp3.Items.Add($_.NetConnectionID)} | Out-Null
$drp3.SelectedIndex = 0

$frm1.AcceptButton = $btn1
$frm1.CancelButton = $btn2

$frm1.Controls.Add($pnl1)
$frm1.Controls.Add($btn1)
$frm1.Controls.Add($btn2)
$pnl1.Controls.Add($lbl0)
$pnl1.Controls.Add($lbl1)

$frm1.Controls.Add($lbl2)
$frm1.Controls.Add($lbl3)
$frm1.Controls.Add($lbl4)
$frm1.Controls.Add($lbl5)
$frm1.Controls.Add($lbl6)
$frm1.Controls.Add($lbl7)
$frm1.Controls.Add($lbl8)
$frm1.Controls.Add($txt1)
$frm1.Controls.Add($txt2)
$frm1.Controls.Add($txt3)
$frm1.Controls.Add($drp1)
$frm1.Controls.Add($drp2)
$frm1.Controls.Add($drp3)

$frm1.ActiveControl = $txt1

#メイン処理
#----------------------------------------------------------------------------------------------------

#フォーム表示
$frm1.ShowDialog()

exit 0
