" writebackup.vim: Write backups of current file with date file extension.  
"
" DEPENDENCIES:
"   - Requires VIM 7.0 or higher. 
"
" Copyright: (C) 2007-2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
let s:version = 131
" REVISION	DATE		REMARKS 
"   1.31.013	16-Feb-2009	Split off documentation into separate help file. 
"   1.30.012	13-Feb-2009	Extracted version number and put on a more
"				prominent place, so that it gets updated. 
"   1.30.011	11-Feb-2009	BF: On Unix, fnamemodify() doesn't simplify the
"				'/./' part; added explicit simplify() call. 
"   1.30.010	24-Jan-2009	BF: Unnamed buffers were backed up as
"				'.YYYYMMDDa'; now checking for empty original
"				filespec and throwing exception. 
"				BF: Now also allowing relative backup dir
"				in an upper directory (i.e.
"				g:WriteBackup_BackupDir starting with '../'. 
"   1.30.009	23-Jan-2009	ENH: The backup directory can now be determined
"				dynamically through a callback function. 
"				Renamed configuration variable from
"				g:writebackup_BackupDir to
"				g:WriteBackup_BackupDir. 
"   1.20.008	16-Jan-2009	Now setting v:errmsg on errors. 
"   1.20.007	21-Jul-2008	BF: Using ErrorMsg instead of Error highlight
"				group. 
"   1.20.006	13-Jun-2008	Added -bar to :WriteBackup, so that commands can
"				be chained together. 
"   1.20.005	18-Sep-2007	ENH: Added support for writing backup files into
"				a different directory (either one static backup
"				dir or relative to the original file) via
"				g:writebackup_BackupDir configuration, as
"				suggested by Vincent DiCarlo. 
"				Now requiring VIM 7.0 or later, because it's
"				using lists. 
"				BF: Special ex command characters ' \%#' must be
"				escaped for ':w' command. 
"   1.00.004	07-Mar-2007	Added documentation. 
"	0.03	06-Dec-2006	Factored out WriteBackup_GetBackupFilename() to
"				use in :WriteBackupOfSavedOriginal. 
"	0.02	14-May-2004	Avoid that the written file becomes the
"				alternate file (via set cpo-=A)
"	0.01	15-Nov-2002	file creation

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_writebackup') || (v:version < 700)
    finish
endif
let g:loaded_writebackup = s:version

if ! exists('g:WriteBackup_BackupDir')
    let g:WriteBackup_BackupDir = '.'
endif

function! s:GetSettingFromScope( variableName, scopeList )
    for l:scope in a:scopeList
	let l:variable = l:scope . ':' . a:variableName
	if exists( l:variable )
	    execute 'return ' . l:variable
	endif
    endfor
    throw "No variable named '" . a:variableName . "' defined. "
endfunction

function! WriteBackup_GetBackupDir( originalFilespec, isQueryOnly )
    if empty(a:originalFilespec)
	throw 'WriteBackup: No file name'
    endif
    let l:BackupDir = s:GetSettingFromScope( 'WriteBackup_BackupDir', ['b', 'g'] )
    if type(l:BackupDir) == type('')
	return l:BackupDir
    else
	return call(l:BackupDir, [a:originalFilespec, a:isQueryOnly])
    endif
endfunction

function! WriteBackup_AdjustFilespecForBackupDir( originalFilespec, isQueryOnly )
    let l:backupDir = WriteBackup_GetBackupDir(a:originalFilespec, a:isQueryOnly)
    if l:backupDir == '.'
	" The backup will be placed in the same directory as the original file. 
	return a:originalFilespec
    endif

    let l:originalDirspec = fnamemodify( a:originalFilespec, ':p:h' )
    let l:originalFilename = fnamemodify( a:originalFilespec, ':t' )

    let l:adjustedDirspec = ''
    " Note: On Windows, fnamemodify( 'path/with/./', ':p' ) will convert the
    " forward slashes to backslashes by triggering a path simplification of the
    " '/./' part. On Unix, simplify() will get rid of the '/./' part. 
    if l:backupDir =~# '^\.\.\?[/\\]'
	" Backup directory is relative to original file. 
	" Modify dirspec into something relative to CWD. 
	let l:adjustedDirspec = fnamemodify( simplify(fnamemodify( l:originalDirspec . '/' . l:backupDir . '/', ':p' )), ':.' )
    else
	" One common backup directory for all original files. 
	" Modify dirspec into an absolute path. 
	let l:adjustedDirspec = simplify(fnamemodify( l:backupDir . '/./', ':p' ))
    endif
    if ! isdirectory( l:adjustedDirspec ) && ! a:isQueryOnly
	throw "WriteBackup: Backup directory '" . fnamemodify( l:adjustedDirspec, ':p' ) . "' does not exist!"
    endif
    return l:adjustedDirspec . l:originalFilename
endfunction

function! WriteBackup_GetBackupFilename( originalFilespec )
    let l:date = strftime( "%Y%m%d" )
    let l:nr = 'a'
    while( l:nr <= 'z' )
	let l:backupFilespec = WriteBackup_AdjustFilespecForBackupDir( a:originalFilespec, 0 ) . '.' . l:date . l:nr
	if( filereadable( l:backupFilespec ) )
	    " Current backup letter already exists, try next one. 
	    " Vim script cannot increment characters; so convert to number for increment. 
	    let l:nr = nr2char( char2nr(l:nr) + 1 )
	    continue
	endif
	" Found unused backup letter. 
	return l:backupFilespec
    endwhile

    " All backup letters a-z are already used; report error. 
    throw 'WriteBackup: Ran out of backup file names'
endfunction

function! s:WriteBackup()
    let l:saved_cpo = &cpo
    set cpo-=A
    try
	let l:backupFilespecInVimSyntax = escape( tr( WriteBackup_GetBackupFilename(expand('%')), '\', '/' ), ' \%#')
	execute 'write ' . l:backupFilespecInVimSyntax
    catch /^WriteBackup:/
	echohl ErrorMsg
	let v:errmsg = substitute(v:exception, '^WriteBackup:\s*', '', '')
	echomsg v:errmsg
	echohl None
    catch /^Vim\%((\a\+)\)\=:E/
	echohl ErrorMsg
	let v:errmsg = substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '')
	echomsg v:errmsg
	echohl None
    finally
	let &cpo = l:saved_cpo
    endtry
endfunction

command! -bar WriteBackup call <SID>WriteBackup()

unlet s:version
" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
