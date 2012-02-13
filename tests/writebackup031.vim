" Test avoiding backups identical to last backup. 
" Tests that no backup file is created when the original file is unmodified. 

runtime plugin/writebackupVersionControl.vim

cd $TEMP/WriteBackupTest
edit important.txt
%s/current/fourth/
%s/simplified/removed a line/
write
echomsg 'Test: Saved original is identical to old backup'
WriteBackup

%s/fourth/fifth/
write
WriteBackup
echomsg 'Test: Saved original is identical to recent backup'
WriteBackup

call ListFiles()
call vimtest#Quit() 

