" Test forcing disallowed backup with bang.

cd $TEMP/WriteBackupTest
edit important.txt

let g:WriteBackup_ExclusionPredicates = ['1']
WriteBackup!

call ListFiles()
call vimtest#Quit()
