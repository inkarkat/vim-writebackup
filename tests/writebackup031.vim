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

call vimtap#err#Errors("This file is already backed up as '20080101b'", 'WriteBackup', 'already backed up error shown')

%s/fourth/fifth/
write
WriteBackup
call vimtap#err#ErrorsLike("This file is already backed up as '20\\d\\{6}a'", 'WriteBackup', 'identical backup error shown')

call ListFiles()
call vimtest#Quit()
