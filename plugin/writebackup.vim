" Write subsequent backups of current file with date file extension (format
" '.YYYYMMDD[a-z]' in the same directory as the file itself. The first backup
" file has letter 'a' appended, the next 'b', and so on. 
"
" DEPENDENCIES:
"   - Requires VIM 6.2. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" REVISION	DATE		REMARKS 
"	0.03	06-Dec-2006	Factored out WriteBackup_GetBackupFilename() to
"				use in :WriteBackupOfSavedOriginal. 
"	0.02	14-May-2004	Avoid that the written file becomes the
"				alternate file (via set cpo-=A)
"	0.01	15-Nov-2002	file creation

" Avoid installing twice or when in compatible mode
if exists("loaded_writebackup") || v:version < 602
    finish
endif
let loaded_writebackup = 1

function! WriteBackup_GetBackupFilename()
    let l:date = strftime( "%Y%m%d" )
    let l:nr = 'a'
    while( l:nr <= 'z' )
	let l:backupfilename = expand("%").'.'.l:date.l:nr
	if( filereadable( l:backupfilename ) )
	    " Current backup letter already exists, try next one. 
	    " Vim script cannot increment characters; so convert to number for increment. 
	    let l:nr = nr2char( char2nr(l:nr) + 1 )
	    continue
	endif
	" Found unused backup letter. 
	return l:backupfilename
    endwhile

    " All backup letters a-z are already used; report error. 
    throw 'WriteBackup: Ran out of backup file names'
endfunction

function! s:WriteBackup()
    try
	let l:saved_cpo = &cpo
	set cpo-=A
	execute 'write ' . WriteBackup_GetBackupFilename()
    catch /^WriteBackup:/
	" All backup letters a-z are already used; report error. 
	echohl Error
	echomsg "Ran out of backup file names"
	echohl None
    catch /^Vim\%((\a\+)\)\=:E/
	echohl Error
	echomsg substitute( v:exception, '^Vim\%((\a\+)\)\=:', '', '' )
	echohl None
    finally
	let &cpo = l:saved_cpo
    endtry
endfunction

command! WriteBackup :call <SID>WriteBackup()

