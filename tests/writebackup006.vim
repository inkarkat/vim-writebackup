" Test writing of backup of backup file. 
" Tests that no backup file is created and an error message is printed. 
" Tests that this cannot be overruled with !. 

runtime plugin/writebackupVersionControl.vim

cd $TEMP/WriteBackupTest
edit important.txt.20080101b
%s/fourth/4th/
WriteBackup
WriteBackup!

call ListFiles()
call vimtest#Quit() 

