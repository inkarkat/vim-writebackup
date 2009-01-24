" Test writing of backups in a non-existing directory. 
" Tests that no backup file is created and an error message is printed. 

source helpers/canonicalize.vim
source helpers/listfiles.vim
silent ! setup

let g:WriteBackup_BackupDir = $TEMP . '/WriteBackupTest/doesnotexist'
cd $TEMP/WriteBackupTest
edit important.txt
WriteBackup
echomsg CanonicalizeFilespecVariable(v:errmsg, 'g:WriteBackup_BackupDir')
%s/current/fifth/
w

call ListFiles(expand('<sfile>'))
if exists('g:debug') && g:debug | finish | else | quitall! | endif

