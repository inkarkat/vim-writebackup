" Test running out and forcing backup. 

cd $TEMP/WriteBackupTest
edit important.txt
for i in range(1, 26)
    WriteBackup!
endfor
%s/current/fifth/
WriteBackup!

call ListFiles()
call vimtest#Quit() 

