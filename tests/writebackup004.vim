" Test running out of backup filenames.

cd $TEMP/WriteBackupTest
edit important.txt
for i in range(1, 26)
    WriteBackup!
endfor
%s/current/fifth/

call vimtest#StartTap()
call vimtap#Plan(2)

call vimtap#err#Errors('Ran out of backup file names', 'WriteBackup', 'error shown')

call vimtap#err#Errors('Ran out of backup file names', 'WriteBackup', 'error shown on retry')

call ListFiles()
call vimtest#Quit()
