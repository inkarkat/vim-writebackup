" Test running out of backup filenames.

cd $TEMP/WriteBackupTest
edit important.txt
for i in range(1, 26)
    WriteBackup!
endfor
%s/current/fifth/

call vimtest#StartTap()
call vimtap#Plan(2)

try
    WriteBackup
    call vimtap#Fail('expected error after exhausting all backup filenames')
catch
    call vimtap#err#Thrown('Ran out of backup file names', 'error shown')
endtry

try
    WriteBackup
    call vimtap#Fail('expected error after trying once more')
catch
    call vimtap#err#Thrown('Ran out of backup file names', 'error shown on retry')
endtry

call ListFiles()
call vimtest#Quit()
