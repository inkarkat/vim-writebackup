" Test avoiding backups identical to last backup. 
" Tests that an identical old backup file is re-dated when the original file is modified. 

call vimtest#ErrorAndQuitIf(g:WriteBackup_AvoidIdenticalBackups !=# 'redate', 'Default behavior on identical backups is redate')
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
