" Test avoiding backups identical to last backup. 
" Tests that no backup file is created when the original file is modified. 

let g:WriteBackup_AvoidIdenticalBackups = 1
runtime plugin/writebackupVersionControl.vim

cd $TEMP/WriteBackupTest
edit important.txt
%s/current/fourth/
%s/simplified/removed a line/
"write
echomsg 'Test: Writing identical to old backup'
WriteBackup

edit! important.txt
%s/current/fifth/
WriteBackup
echomsg 'Test: Writing identical to recent backup'
WriteBackup

call ListFiles()
call vimtest#Quit() 
