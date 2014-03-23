" Test writing of backups in a dynamic directory.
" Tests returning of the current dir and a relative dir.
" Tests aborting the backup via 'WriteBackup:' exception.
" Tests aborting via Vim error.

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

call vimtest#StartTap()
call vimtap#Plan(2)

edit not\ important.txt
try
    WriteBackup
    call vimtap#Fail('expected error on unimportant file')
catch
    call vimtap#err#Thrown("Don't backup unimportant files", 'error shown')
endtry


edit someplace\ else.txt
cd $VIM
WriteBackup

file causing\ error.txt
try
    WriteBackup
    call vimtap#Fail('expected error after causing Vim error during backup dir resolution')
catch
    call vimtap#err#Thrown('E117: Unknown function: s:DoesNotExist', 'error shown')
endtry

call ListFiles()
call vimtest#Quit()
