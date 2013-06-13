" Test writing of backups in a dynamic directory. 
" Tests returning of the current dir and a relative dir. 
" Tests aborting the backup via 'WriteBackup:' exception. 
" Tests aborting via VIM error. 

function! MyBackupDir(originalFilespec, isQueryOnly)
    let l:originalFilename = fnamemodify(a:originalFilespec, ':t')
    if l:originalFilename =~? 'not important'
	throw 'WriteBackup: Don''t backup unimportant files'
    elseif l:originalFilename =~? 'else'
	return './backup'
    elseif l:originalFilename =~? 'error'
	return s:DoesNotExist('not', 'here')
    else
	return '.'
    endif
endfunction

unlet g:WriteBackup_BackupDir
let g:WriteBackup_BackupDir = function('MyBackupDir')
cd $TEMP/WriteBackupTest

edit important.txt
%s/current/fifth/
WriteBackup
%s/fifth/CURRENT/
write

edit not\ important.txt
echomsg 'Test: This file won''t be backed up.'
WriteBackup

edit someplace\ else.txt
cd $VIM
WriteBackup

file causing\ error.txt
echomsg 'Test: Causing VIM error during backup dir resolution'
WriteBackup

call ListFiles()
call vimtest#Quit() 

