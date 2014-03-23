" Test avoiding backups identical to last backup.
" Tests that no backup file is created when the original file is unmodified.

let g:WriteBackup_AvoidIdenticalBackups = 1
runtime plugin/writebackupVersionControl.vim

cd $TEMP/WriteBackupTest
edit important.txt
%s/current/fourth/
%s/simplified/removed a line/
write

call vimtest#StartTap()
call vimtap#Plan(2)

try
    WriteBackup
    call vimtap#Fail('expected error on saved original that is identical to old backup')
catch
    call vimtap#err#Thrown("This file is already backed up as '20080101b'", 'already backed up error shown')
endtry

%s/fourth/fifth/
write
WriteBackup
try
    WriteBackup
    call vimtap#Fail('expected error when saved original is identical to recent backup')
catch
    call vimtap#err#ThrownLike("This file is already backed up as '20\\d\\{6}a'", 'identical backup error shown')
endtry

call ListFiles()
call vimtest#Quit()
