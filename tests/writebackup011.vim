" Test writing of backups in a different absolute directory. 
" Tests that the backup file is created in that directory regardless of the
" file's dir and CWD. 

let g:WriteBackup_BackupDir = $TEMP . '/WriteBackupTest/backup'
if exists('+autochdir') | set noautochdir | endif
cd $TEMP/WriteBackupTest
edit important.txt
%s/current/fifth/
WriteBackup
cd backup
%s/fifth/sixth/
WriteBackup
cd $VIM
%s/sixth/seventh/
WriteBackup
%s/seventh/CURRENT/
w

cd $TEMP/WriteBackupTest
edit another\ dir/some\ file.txt
WriteBackup

call ListFiles()
call vimtest#Quit() 

