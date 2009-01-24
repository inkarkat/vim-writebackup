" Test writing of backups in a different relative directory. 
" Tests that the backup file is created in that directory regardless of the CWD. 

source helpers/canonicalize.vim
source helpers/listfiles.vim
silent ! setup

let g:WriteBackup_BackupDir = './backup'
cd $TEMP/WriteBackupTest
edit important.txt
%s/current/fifth/
WriteBackup
cd backup
%s/fifth/sixth/
WriteBackup
cd $VIM
%s/sixth/seventh/
WriteBackup
%s/seventh/CURRENT/
w

cd $TEMP/WriteBackupTest
edit another\ dir/some\ file.txt
echomsg 'Test: Should complain that the relative directory does not exist.'
WriteBackup
echomsg CanonicalizeFilespec(v:errmsg, $TEMP . '/WriteBackupTest', '.../')

saveas $TEMP/WriteBackupTest/another\ dir/new\ file
echomsg 'Test: Should complain that the relative directory does not exist.'
WriteBackup
echomsg CanonicalizeFilespec(v:errmsg, $TEMP . '/WriteBackupTest', '.../')
let b:WriteBackup_BackupDir = '../backup'
WriteBackup
cd $VIM
%s/just/more/
WriteBackup


call ListFiles(expand('<sfile>'))
if exists('g:debug') && g:debug | finish | else | quitall! | endif

