" Test writing of backup of unnamed buffer. 
" Tests that no backup file is created and an error message is printed. 

cd $TEMP/WriteBackupTest
enew
normal! i# contents
WriteBackup

call ListFiles()
call vimtest#Quit() 

