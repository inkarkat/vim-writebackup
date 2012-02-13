" Test forcing backup identical to last backup. 

runtime plugin/writebackupVersionControl.vim

cd $TEMP/WriteBackupTest
edit important.txt
%s/current/fourth/
%s/simplified/removed a line/
echomsg 'Test: Writing identical to old backup'
WriteBackup!

write
echomsg 'Test: Saved original is identical to recent backup'
WriteBackup!

call ListFiles()
call vimtest#Quit() 

