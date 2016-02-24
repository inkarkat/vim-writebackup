" Test writing of backups with special names.
" Tests spaces, upper/lowercase and special Ex command characters like % and #.

cd $TEMP/WriteBackupTest
enew
normal! i# contents
saveas! test\ With\ SpAcEs.TXT
WriteBackup
saveas! my\ \#\ very\ \%.strange.FILE.txt
WriteBackup
saveas! concise
WriteBackup

call ListFiles()
call vimtest#Quit()
