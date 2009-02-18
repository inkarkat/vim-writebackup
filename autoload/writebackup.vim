" writebackup.vim: Write backups of current file with date file extension.  
"
" DEPENDENCIES:
"
" Copyright: (C) 2007-2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   2.00.002	18-Feb-2009	ENH: Disallowing backup of backup file if
"				writebackupVersionControl plugin is installed. 
"   2.00.001	17-Feb-2009	Moved functions from plugin to separate autoload
"				script. 
"				Replaced global WriteBackup_...() functions with
"				autoload functions writebackup#...(). This is an
"				incompatible change that also requires the
"				corresponding writebackupVersionControl.vim
"				version. 
"				file creation

function! s:GetSettingFromScope( variableName, scopeList )
    for l:scope in a:scopeList
	let l:variable = l:scope . ':' . a:variableName
	if exists( l:variable )
	    execute 'return ' . l:variable
	endif
    endfor
    throw "No variable named '" . a:variableName . "' defined. "
endfunction

function! s:ExistsWriteBackupVersionControlPlugin()
    " Do not check for the plugin version of writebackupVersionControl here;
    " that plugin has the mandatory dependency to this plugin and will ensure
    " that the versions are compatible. 
    return exists('g:loaded_writebackupVersionControl') && g:loaded_writebackupVersionControl
endfunction

function! writebackup#GetBackupDir( originalFilespec, isQueryOnly )
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

function! writebackup#AdjustFilespecForBackupDir( originalFilespec, isQueryOnly )
    let l:backupDir = writebackup#GetBackupDir(a:originalFilespec, a:isQueryOnly)
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

function! writebackup#GetBackupFilename( originalFilespec )
    let l:date = strftime( "%Y%m%d" )
    let l:nr = 'a'
    while( l:nr <= 'z' )
	let l:backupFilespec = writebackup#AdjustFilespecForBackupDir( a:originalFilespec, 0 ) . '.' . l:date . l:nr
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

function! writebackup#WriteBackup()
    let l:saved_cpo = &cpo
    set cpo-=A
    try
	let l:originalFilespec = expand('%')
	if s:ExistsWriteBackupVersionControlPlugin() && ! writebackupVersionControl#IsOriginalFile(l:originalFilespec)
	    throw 'WriteBackup: You can only backup the latest file version, not a backup file itself!'
	endif

	let l:backupFilespecInVimSyntax = escape( tr( writebackup#GetBackupFilename(l:originalFilespec), '\', '/' ), ' \%#')
	execute 'write ' . l:backupFilespecInVimSyntax
    catch /^WriteBackup\%(VersionControl\)\?:/
	echohl ErrorMsg
	let v:errmsg = substitute(v:exception, '^WriteBackup\%(VersionControl\)\?:\s*', '', '')
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

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
