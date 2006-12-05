" Write subsequent backups of current file with date file extension (format
" '.YYYYMMDD[a-z]' in the same directory as the file itself. The first backup
" file has letter 'a' appended, the next 'b', and so on. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" REVISION	DATE		REMARKS 
"	0.02	14-May-2004	Avoid that the written file becomes the
"				alternate file (via set cpo-=A)
"	0.01	15-Nov-2002	file creation

" Avoid installing twice or when in compatible mode
if exists("loaded_writebackup")
    finish
endif
let loaded_writebackup = 1

function s:WriteBackup()
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
	" Found unused backup letter; write backup and exit. 
	let l:saved_cpo = &cpo
	set cpo-=A
	execute "write ".l:backupfilename
	let &cpo = l:saved_cpo
	return
    endwhile
 
    " All backup letters a-z are already used; report error. 
    echohl Error
    echo "Ran out of backup file names"
    echohl None
endfunction

command WriteBackup :call <SID>WriteBackup()

