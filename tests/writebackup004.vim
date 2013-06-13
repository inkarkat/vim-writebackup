" Test running out of backup filenames. 

cd $TEMP/WriteBackupTest
edit important.txt
for i in range(1, 26)
    WriteBackup!
endfor
%s/current/fifth/
echomsg 'Test: Exhausted all backup filenames'
WriteBackup
echomsg 'Test: Trying once more'
WriteBackup

call ListFiles()
call vimtest#Quit() 

