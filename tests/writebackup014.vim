" Test writing of backups in a different relative directory.
" Tests that the backup file is created in that directory regardless of the CWD.

call vimtest#SkipAndQuitIf(! isdirectory($VIM), '$VIM (' . $VIM . ') does not exist')

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
write

call vimtest#StartTap()
call vimtap#Plan(2)

cd $TEMP/WriteBackupTest
edit another\ dir/some\ file.txt
call vimtap#err#ErrorsLike("Backup directory '.*[/\\\\]WriteBackupTest[/\\\\]another dir[/\\\\]backup[/\\\\]\\?' does not exist!", 'WriteBackup', 'error shown')

saveas $TEMP/WriteBackupTest/another\ dir/new\ file
call vimtap#err#ErrorsLike("Backup directory '.*[/\\\\]WriteBackupTest[/\\\\]another dir[/\\\\]backup[/\\\\]\\?' does not exist!", 'WriteBackup', 'error shown')

let b:WriteBackup_BackupDir = '../backup'
WriteBackup
cd $VIM
%s/just/more/
WriteBackup

call ListFiles()
call vimtest#Quit()
