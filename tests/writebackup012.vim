" Test writing of backups in a non-existing directory. 
" Tests that no backup file is created and an error message is printed. 

let g:WriteBackup_BackupDir = $TEMP . '/WriteBackupTest/doesnotexist'
cd $TEMP/WriteBackupTest
edit important.txt
WriteBackup
%s/current/fifth/
write

call ListFiles()
call vimtest#Quit()

