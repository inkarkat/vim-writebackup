" writebackup.vim: Write backups of current file with date file extension.
"
" DEPENDENCIES:
"   - ingo-library.vim plugin
"   - writebackupVersionControl.vim plugin (optional)
"
" Copyright: (C) 2007-2021 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

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
    let l:BackupDir = ingo#plugin#setting#GetBufferLocal('WriteBackup_BackupDir')
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

    let l:originalDirspec = fnamemodify(a:originalFilespec, ':p:h')
    let l:originalFilename = fnamemodify(a:originalFilespec, ':t')

    let l:adjustedDirspec = ''
    " Note: On Windows, fnamemodify('path/with/./', ':p') will convert the
    " forward slashes to backslashes by triggering a path simplification of the
    " '/./' part. On Unix, simplify() will get rid of the '/./' part.
    if l:backupDir =~# '^\.\.\?[/\\]'
	" Backup directory is relative to original file.
	let l:dirspec = simplify(fnamemodify(l:originalDirspec . '/' . l:backupDir . '/', ':p'))

	" Modify dirspec into something relative to CWD.
	let l:adjustedDirspec = fnamemodify(l:dirspec, ':.' )
    else
	" One common backup directory for all original files.
	let l:dirspec = simplify(fnamemodify(l:backupDir . '/./', ':p'))

	" Dirspec should be (and already is) an absolute path.
	let l:adjustedDirspec = l:dirspec
    endif
    if ! isdirectory(l:adjustedDirspec) && ! a:isQueryOnly
	throw printf("WriteBackup: Backup directory '%s' does not exist!", l:dirspec)
    endif
    return l:adjustedDirspec . l:originalFilename
endfunction

function! s:GetDate() abort
    return strftime('%Y%m%d')
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
    let l:date = s:GetDate()
    let l:nr = 'a'
    while l:nr <= 'z'
	let l:backupFilespec = writebackup#AdjustFilespecForBackupDir(a:originalFilespec, 0) . '.' . l:date . l:nr
	if(filereadable(l:backupFilespec))
	    " Current backup letter already exists, try next one.
	    " Vimscript cannot increment characters; so convert to number for increment.
	    let l:nr = nr2char(char2nr(l:nr) + 1)
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

function! writebackup#ShouldRedateIdenticalBackup( backupFilespec )
    let l:backupNr = strpart(a:backupFilespec, len(a:backupFilespec) - 1)
    return (l:backupNr ==# 'a')
endfunction
function! writebackup#Redate( identicalPredecessorFilespec, backupFilespec )
"******************************************************************************
"* PURPOSE:
"   Rename the earlier identical predecessor to today's first backup.
"* ASSUMPTIONS / PRECONDITIONS:
"   None.
"* EFFECTS / POSTCONDITIONS:
"   Renames a:identicalPredecessorFilespec to a:backupFilespec.
"* INPUTS:
"   a:identicalPredecessorFilespec  Existing backup file.
"   a:backupFilespec		    Next available backup filespec.
"* RETURN VALUES:
"   None.
"   Throws 'WriteBackup: Failed to redate '<version>' as '<version>''.
"******************************************************************************
    let l:identicalPredecessorVersion = writebackupVersionControl#GetVersion(a:identicalPredecessorFilespec)
    if rename(a:identicalPredecessorFilespec, a:backupFilespec) == 0
	echomsg printf("This file was already backed up as '%s'; redated as '%s'",
	\	l:identicalPredecessorVersion,
	\	writebackupVersionControl#GetVersion(a:backupFilespec)
	\)
    else
	throw printf("WriteBackup: Failed to redate '%s' as '%s'",
	\	l:identicalPredecessorVersion,
	\	writebackupVersionControl#GetVersion(a:backupFilespec)
	\)
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
    try
	let l:originalFilespec = expand('%')
	let l:isNeedToCheckForIdenticalPredecessorAfterBackup = 0

	if ! a:isForced
	    for l:ExclusionPredicate in g:WriteBackup_ExclusionPredicates
		let l:excluded = ingo#actions#EvaluateOrFunc(l:ExclusionPredicate)
		if ! empty(l:excluded)
		    throw 'WriteBackup: ' . (type(l:excluded) == type('') ? l:excluded : 'Backup is disallowed') . ' (add ! to override)'
		endif
	    endfor
	endif

	if s:ExistsWriteBackupVersionControlPlugin()
	    if ! writebackupVersionControl#IsOriginalFile(l:originalFilespec)
		throw 'WriteBackup: You can only backup the latest file version, not a backup file itself!'
	    elseif ! a:isForced && g:WriteBackup_AvoidIdenticalBackups !=# '0'
		" Identical backups are to be avoided.
		if &l:modified
		    " The current buffer is modified; we can only check for an
		    " identical backup after the buffer has been written.
		    let l:isNeedToCheckForIdenticalPredecessorAfterBackup = 1
		else
		    " As the current buffer isn't modified, we just need to compare
		    " the saved buffer contents with the last backup (if that
		    " exists).
		    let l:identicalPredecessorFilespec = writebackupVersionControl#IsIdenticalWithPredecessor(l:originalFilespec)
		    if ! empty(l:identicalPredecessorFilespec)
			if g:WriteBackup_AvoidIdenticalBackups ==# 'redate'
			    let l:backupFilespec = writebackup#GetBackupFilename(l:originalFilespec, 0)
			    if writebackup#ShouldRedateIdenticalBackup(l:backupFilespec)
				" This would be today's first backup, but an
				" earlier identical backup exists, so just
				" rename that to represent today's first backup.
				call writebackup#Redate(l:identicalPredecessorFilespec, l:backupFilespec)
				return 1
			    endif
			endif

			let l:identicalPredecessorVersion = writebackupVersionControl#GetVersion(l:identicalPredecessorFilespec)
			throw printf("WriteBackup: This file is already backed up as '%s'", l:identicalPredecessorVersion)
		    endif
		endif
	    endif
	endif

	" Perform the backup.
	if ! exists('l:backupFilespec') | let l:backupFilespec = writebackup#GetBackupFilename(l:originalFilespec, a:isForced) | endif
	let l:backupExFilespec = ingo#compat#fnameescape(l:backupFilespec)
	execute 'keepalt write' . (a:isForced ? '!' : '')  l:backupExFilespec

	if l:isNeedToCheckForIdenticalPredecessorAfterBackup
	    let l:identicalPredecessorFilespec = writebackupVersionControl#IsIdenticalWithPredecessor(l:backupFilespec)
	    if ! empty(l:identicalPredecessorFilespec)
		let l:identicalPredecessorVersion = writebackupVersionControl#GetVersion(l:identicalPredecessorFilespec)
		if g:WriteBackup_AvoidIdenticalBackups ==# 'redate'
		    if writebackup#ShouldRedateIdenticalBackup(l:backupFilespec)
			" This was today's first backup, and an earlier
			" identical backup exists, so remove the earlier
			" identical backup.
			call writebackupVersionControl#DeleteBackup(l:identicalPredecessorFilespec, 1) " Try deleting a read-only predecessor, as no information will be lost. If this should fail, we'll get an exception.
			echomsg printf("This file was already backed up as '%s'; redated as '%s'",
			\   l:identicalPredecessorVersion,
			\   writebackupVersionControl#GetVersion(l:backupFilespec)
			\)
			return 1
		    endif
		endif

		call writebackupVersionControl#DeleteBackup(l:backupFilespec, 1)    " This backup was just created, it's unlikely that it's readonly.
		throw printf("WriteBackup: This file is already backed up as '%s'", l:identicalPredecessorVersion)
	    endif
	endif

	return 1
    catch /^WriteBackup\%(VersionControl\)\?:/
	call ingo#err#SetCustomException('WriteBackup\%(VersionControl\)\?')
	return 0
    catch
	call ingo#err#SetVimException()
	return 0
    endtry
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
