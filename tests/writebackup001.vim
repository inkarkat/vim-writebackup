" Test straightforward writing of backups. 
" Tests that the backup file is created in the same directory regardless of the
" CWD. 

cd $TEMP/WriteBackupTest
edit important.txt
%s/current/fifth/
WriteBackup
cd ..
%s/fifth/sixth/
WriteBackup
cd $VIM
%s/sixth/seventh/
WriteBackup
%s/seventh/CURRENT/
write

call ListFiles()
call vimtest#Quit() 

