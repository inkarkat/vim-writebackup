" writebackup.vim: Write backups of current file with date file extension.  
"
" DEPENDENCIES:
"   - escapings.vim autoload script. 
"
" Copyright: (C) 2007-2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   2.10.005	27-May-2009	Replaced simple filespec escaping with
"				built-in fnameescape() function (or emulation
"				for Vim 7.0 / 7.1) via escapings.vim wrapper. 
"   2.00.004	22-Feb-2009	ENH: Added a:isForced argument to
"				writebackup#WriteBackup() to allow forcing via
"				:WriteBackup!. 
"   2.00.003	21-Feb-2009	ENH: No backup is written if there is an
"				identical previous backup. This requires the
"				writebackupVersionControl plugin and can be
"				configured via
"				g:WriteBackup_AvoidIdenticalBackups. 
"   2.00.002	18-Feb-2009	ENH: Disallowing backup of backup file if
"				writebackupVersionControl plugin is installed. 
"				BF: On Linux, if the backup directory doesn't
"				exist, the exception thrown in
"				writebackup#AdjustFilespecForBackupDir() does
"				not contain the absolute dirspec, because (on
"				Linux, not on Windows), the
"				fnamemodify(...,':p') call does not resolve to
"				an absolute filespec if the file doesn't exist.
"				(This is okay and mentioned in the help). 
"				Now keeping an intermediate variable l:dirspec
"				(that contains the absolute dirspec) instead of
"				trying to re-create the absolute missing
"				dirspec from l:adjustedDirspec. 
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
	let l:dirspec = simplify(fnamemodify( l:originalDirspec . '/' . l:backupDir . '/', ':p' ))

	" Modify dirspec into something relative to CWD. 
	let l:adjustedDirspec = fnamemodify(l:dirspec, ':.' )
    else
	" One common backup directory for all original files. 
	let l:dirspec = simplify(fnamemodify( l:backupDir . '/./', ':p' ))

	" Dirspec should be (and already is) an absolute path. 
	let l:adjustedDirspec = l:dirspec
    endif
    if ! isdirectory( l:adjustedDirspec ) && ! a:isQueryOnly
	throw printf("WriteBackup: Backup directory '%s' does not exist!", l:dirspec)
    endif
    return l:adjustedDirspec . l:originalFilename
endfunction

function! writebackup#GetBackupFilename( originalFilespec, isForced )
"*******************************************************************************
"* PURPOSE:
"   Determine the next available backup version and return the backup filename. 
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   None. 
"* INPUTS:
"   a:originalFilespec	Original file.
"   a:isForced	Flag whether running out of backup versions is not allowed, and
"		we'd rather overwrite the last backup. 
"* RETURN VALUES: 
"   Next available backup filespec (that does not yet exist) for
"   a:originalFilespec. If a:isForced is set and no more versions are available,
"   the last (existing) backup filespec ('.YYYYMMDDz') is returned. 
"   Throws 'WriteBackup: Ran out of backup file names'. 
"*******************************************************************************
    let l:date = strftime( "%Y%m%d" )
    let l:nr = 'a'
    while l:nr <= 'z'
	let l:backupFilespec = writebackup#AdjustFilespecForBackupDir( a:originalFilespec, 0 ) . '.' . l:date . l:nr
	if( filereadable( l:backupFilespec ) )
	    " Current backup letter already exists, try next one. 
	    " Vimscript cannot increment characters; so convert to number for increment. 
	    let l:nr = nr2char( char2nr(l:nr) + 1 )
	    continue
	endif
	" Found unused backup letter. 
	return l:backupFilespec
    endwhile

    " All backup letters a-z are already used. 
    if a:isForced
	return l:backupFilespec
    else
	throw 'WriteBackup: Ran out of backup file names'
    endif
endfunction

function! writebackup#WriteBackup( isForced )
"*******************************************************************************
"* PURPOSE:
"   Back up the current buffer contents to the next available backup file. 
"* ASSUMPTIONS / PRECONDITIONS:
"   None. 
"* EFFECTS / POSTCONDITIONS:
"   Writes backup file, or:
"   Prints error message. 
"   May overwrite last backup when running out of backup files and a:isForced. 
"   May create and delete a backup file when buffer is modified and check for
"   identical backups is positive. 
"* INPUTS:
"   a:isForced	Flag whether creation of a new backup file is forced, i.e. even
"		if contents are identical or when no more backup versions (for
"		this day) are available. 
"* RETURN VALUES: 
"   None. 
"*******************************************************************************
    let l:saved_cpo = &cpo
    set cpo-=A
    try
	let l:originalFilespec = expand('%')
	let l:isNeedToCheckForIdenticalPredecessorAfterBackup = 0
	if s:ExistsWriteBackupVersionControlPlugin()
	    if ! writebackupVersionControl#IsOriginalFile(l:originalFilespec)
		throw 'WriteBackup: You can only backup the latest file version, not a backup file itself!'
	    elseif g:WriteBackup_AvoidIdenticalBackups && ! a:isForced
		if &l:modified
		    " The current buffer is modified; we can only check for an
		    " identical backup after the buffer has been written. 
		    let l:isNeedToCheckForIdenticalPredecessorAfterBackup = 1
		else
		    " As the current buffer isn't modified, we just need to compare
		    " the saved buffer contents with the last backup (if that
		    " exists). 
		    let l:currentBackupVersion = writebackupVersionControl#IsIdenticalWithPredecessor(l:originalFilespec)
		    if ! empty(l:currentBackupVersion)
			throw printf("WriteBackup: This file is already backed up as '%s'", l:currentBackupVersion)
		    endif
		endif
	    endif
	endif

	let l:backupFilespec = writebackup#GetBackupFilename(l:originalFilespec, a:isForced)
	let l:backupExFilespec = escapings#fnameescape(l:backupFilespec)
	execute 'write' . (a:isForced ? '!' : '')  l:backupExFilespec

	if l:isNeedToCheckForIdenticalPredecessorAfterBackup
	    let l:identicalPredecessorVersion = writebackupVersionControl#IsIdenticalWithPredecessor(l:backupFilespec)
	    if ! empty(l:identicalPredecessorVersion)
		call writebackupVersionControl#DeleteBackup(l:backupFilespec, 0)
		throw printf("WriteBackup: This file is already backed up as '%s'", l:identicalPredecessorVersion)
	    endif
	endif
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
