" Test writing of backups in a non-existing directory. 
" Tests that no backup file is created and an error message is printed. 

source helpers/canonicalize.vim
source helpers/listfiles.vim
silent ! setup

let g:WriteBackup_BackupDir = $TEMP . '/WriteBackupTest/doesnotexist'
cd $TEMP/WriteBackupTest
edit important.txt
WriteBackup
%s/current/fifth/
w

call ListFiles(expand('<sfile>'))
call vimtest#ProcessMsgout(expand('<sfile>'))
call CanonicalizeFilespecVariable('g:WriteBackup_BackupDir')
call vimtest#Quit()

