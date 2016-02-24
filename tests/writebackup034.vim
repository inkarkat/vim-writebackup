" Test avoiding backups identical to last backup turned off. 
" Tests that identical backups are created when the functionality is explicitly
" turned off. 

let g:WriteBackup_AvoidIdenticalBackups = 0
runtime plugin/writebackupVersionControl.vim

cd $TEMP/WriteBackupTest
edit important.txt
%s/current/fifth/
WriteBackup
WriteBackup

call ListFiles()
call vimtest#Quit() 
