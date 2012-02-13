" Test avoiding backups identical to last backup not available. 
" Tests that identical backups are created when no writebackupVersionControl.vim
" is available. 

cd $TEMP/WriteBackupTest
edit important.txt
%s/current/fifth/
WriteBackup
WriteBackup

call ListFiles()
call vimtest#Quit() 

