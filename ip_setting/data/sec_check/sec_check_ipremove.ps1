
######################################################################
#
# [FileName]
#    sec_check_ipremove.ps1
#
# [Title]
#    Security�`�F�b�N�X�N���v�g(IP-Remove)
#
# [�������e]
#    �@LSC�ASEP�AWSUS�ݒ�̗L�����`�F�b�N���A���O�ɏo�͂��܂�
#    �A�P�\���ԓ���LSC�ASEP�̐ݒ���s��Ȃ������ꍇ�AIP�A�h���X���폜���܂�
#
#    <�O�����>
#    powershell -ExecutionPolicy remotesigned <PS1 File>�Ƃ��Ď��s����
#
# [�߂�l]
#    ����	�Ȃ�
#    �G���[	�Ȃ�
#
######################################################################

#rev
#----------------------------------------------------------------------------------------------------
[string] $rev = "1.0"

[string] $current = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)

[string] $intfile = "$current\sec_check.int"

[string] $interface = Get-Content $intfile -Encoding UTF8

#�G���[��\��
#----------------------------------------------------------------------------------------------------
$ErrorActionPreference = "SilentlyContinue" 

#�R���\�[����\��
#----------------------------------------------------------------------------------------------------
powershell -windowstyle hidden -command exit

#���C������
#----------------------------------------------------------------------------------------------------
netsh int ipv4 set add $interface dhcp
netsh int ipv4 set dns $interface dhcp
netsh int ipv4 set wins $interface dhcp

exit 0
