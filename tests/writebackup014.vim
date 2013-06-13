" Test writing of backups in a different relative directory. 
" Tests that the backup file is created in that directory regardless of the CWD. 

let g:WriteBackup_BackupDir = './backup'
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
write

cd $TEMP/WriteBackupTest
edit another\ dir/some\ file.txt
echomsg 'Test: Should complain that the relative directory does not exist.'
WriteBackup

saveas $TEMP/WriteBackupTest/another\ dir/new\ file
echomsg 'Test: Should complain that the relative directory does not exist.'
WriteBackup
let b:WriteBackup_BackupDir = '../backup'
WriteBackup
cd $VIM
%s/just/more/
WriteBackup

call ListFiles()
call vimtest#Quit()

