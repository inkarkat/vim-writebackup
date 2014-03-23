" Test avoiding backups identical to last backup.
" Tests that an identical old backup file is re-dated when the original file is unmodified.

call vimtest#ErrorAndQuitIf(g:WriteBackup_AvoidIdenticalBackups !=# 'redate', 'Default behavior on identical backups is redate')
runtime plugin/writebackupVersionControl.vim

cd $TEMP/WriteBackupTest
edit important.txt
%s/current/fourth/
%s/simplified/removed a line/
write
echomsg 'Test: Saved original is identical to old backup'
WriteBackup


call vimtest#StartTap()
call vimtap#Plan(1)

%s/fourth/fifth/
write
WriteBackup
try
    WriteBackup
    call vimtap#Fail('expected error when saved original is identical to recent backup')
catch
    call vimtap#err#ThrownLike("This file is already backed up as '20\\d\\{6}b'", 'identical backup error shown')
endtry

call ListFiles()
call vimtest#Quit()
