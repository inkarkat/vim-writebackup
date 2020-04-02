" Test disallowing a backup causes an error.

cd $TEMP/WriteBackupTest
edit important.txt

call vimtest#StartTap()
call vimtap#Plan(3)

let g:WriteBackup_ExclusionPredicates = ['1 == 1']
call vimtap#err#Errors('Backup is disallowed (add ! to override)', 'WriteBackup', 'generic error shown')

function! Predicate() abort
    return 'Custom denial message'
endfunction
let g:WriteBackup_ExclusionPredicates = [function('Predicate')]
call vimtap#err#Errors('Custom denial message (add ! to override)', 'WriteBackup', 'custom error shown')

let g:WriteBackup_ExclusionPredicates = ['0', "'second one'", function('Predicate')]
call vimtap#err#Errors('second one (add ! to override)', 'WriteBackup', 'first denial from second predicate shown')

call ListFiles()
call vimtest#Quit()
