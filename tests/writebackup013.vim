" Test buffer-local writing of backups in a different directory. 

cd $TEMP/WriteBackupTest
edit important.txt
let b:WriteBackup_BackupDir = $TEMP . '/WriteBackupTest/backup'
WriteBackup
split not\ important.txt
WriteBackup
wincmd p
WriteBackup

call ListFiles()
call vimtest#Quit() 

