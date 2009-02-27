" Test side effects of backups. 
" Tests that writing the backup file doesn't reset the 'modified' flag. 
" Tests that writing the backup file doesn't change the CWD. 

call vimtest#StartTap(expand('<sfile>'))
call vimtap#Plan(5)
cd $TEMP/WriteBackupTest
edit important.txt
cd $VIM
let s:savedCwd = getcwd()
call vimtap#Is(&modified, 0, 'First unmodified buffer')
%s/current/fifth/
call vimtap#Is(&modified, 1, 'Modified buffer after substitution')
WriteBackup
call vimtap#Is(&modified, 1, 'Still modified buffer after backup')
call vimtap#Is(getcwd(), s:savedCwd, 'CWD has not changed after backup')
%s/fifth/CURRENT/
write
call vimtap#Is(&modified, 0, 'Finally buffer is saved')

call ListFiles()
call vimtest#Quit() 

