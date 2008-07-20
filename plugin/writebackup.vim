" writebackup.vim: Write backups of current file with date file extension.  
"
" DESCRIPTION:
"   This is a poor man's revision control system, a primitive alternative to
"   CVS, RCS, Subversion, etc., which works with no additional software and
"   almost any file system. 
"   The ':WriteBackup' command writes subsequent backups of the current file
"   with a 'current date + counter' file extension (format '.YYYYMMDD[a-z]').  
"   The first backup of a day has letter 'a' appended, the next 'b', and so on.
"   (Which means that a file can be backed up up to 26 times on any given day.) 
"
"   By default, backups are created in the same directory as the original file,
"   but they can also be placed in a directory relative to the original file, or
"   in one common backup directory for all files (similar to VIM's 'backupdir'
"   option). 
"
" USAGE:
"   :WriteBackup
"
" INSTALLATION:
"   Put the script into your user or system VIM plugin directory (e.g.
"   ~/.vim/plugin). 
"
" DEPENDENCIES:
"   - Requires VIM 7.0 or higher. 
"   - writebackupVersionControl.vim (vimscript #1829) complements this script,
"     but is not required. 
"
" CONFIGURATION:
"   For a permanent configuration, put the following commands into your vimrc
"   file (see :help vimrc). 
"						      *g:writebackup_BackupDir*
"   To put backups into another directory, specify a backup directory via
"	let g:writebackup_BackupDir = 'D:\backups'
"   Please note that this setting may result in name clashes when backing up
"   files with the same name from different directories!
"
"   A directory starting with "./" (or ".\" for MS-DOS et al.) puts the backup
"   file relative to where the backed-up file is.  The leading "." is replaced
"   with the path name of the current file:
"	let g:writebackup_BackupDir = './backups'
"						      *b:writebackup_BackupDir*
"   You can override this global setting for specific buffers via a
"   buffer-scoped variable, which can be set by an autocmd, ftplugin, or
"   manually: 
"	let b:writebackup_BackupDir = 'X:\special\backup\folder'
"
"
"							    *writebackup-alias*
"   In case you already have other custom VIM commands starting with W, you can
"   define a shorter command alias ':W' in your .vimrc to save some keystrokes.
"   I like the parallelism between ':w' for a normal write and ':W' for a backup
"   write. 
"	command -bar W :WriteBackup
"
" Copyright: (C) 2007-2008 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
" REVISION	DATE		REMARKS 
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

" Avoid installing twice or when in compatible mode
if exists('g:loaded_writebackup') || (v:version < 700)
    finish
endif
let g:loaded_writebackup = 120

if ! exists('g:writebackup_BackupDir')
    let g:writebackup_BackupDir = '.'
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

function! WriteBackup_GetBackupDir()
    return s:GetSettingFromScope( 'writebackup_BackupDir', ['b', 'g'] )
endfunction

function! WriteBackup_AdjustFilespecForBackupDir(originalFilespec, isQueryOnly)
    let l:backupDir = WriteBackup_GetBackupDir()
    if l:backupDir == '.'
	" The backup will be placed in the same directory as the original file. 
	return a:originalFilespec
    endif

    let l:originalDirspec = fnamemodify( a:originalFilespec, ':p:h' )
    let l:originalFilename = fnamemodify( a:originalFilespec, ':t' )

    let l:adjustedDirspec = ''
    " Note: fnamemodify( 'path/with/./', ':p' ) will convert the forward slashes
    " to the correct path separators of the platform by triggering a path
    " simplification of the '/./' part. 
    if l:backupDir =~# '^\.[/\\]'
	" Backup directory is relative to original file. 
	" Modify dirspec into something relative to CWD. 
	let l:adjustedDirspec = fnamemodify( fnamemodify( l:originalDirspec . '/' . l:backupDir . '/', ':p' ), ':.' )
    else
	" One common backup directory for all original files. 
	" Modify dirspec into an absolute path. 
	let l:adjustedDirspec = fnamemodify( l:backupDir . '/./', ':p' )
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
    try
	let l:saved_cpo = &cpo
	set cpo-=A
	let l:backupFilespecInVimSyntax = escape( tr( WriteBackup_GetBackupFilename(expand('%')), '\', '/' ), ' \%#')
	execute 'write ' . l:backupFilespecInVimSyntax
    catch /^WriteBackup:/
	echohl Error
	echomsg substitute( v:exception, '^WriteBackup:\s*', '', '' )
	echohl None
    catch /^Vim\%((\a\+)\)\=:E/
	echohl Error
	echomsg substitute( v:exception, '^Vim\%((\a\+)\)\=:', '', '' )
	echohl None
    finally
	let &cpo = l:saved_cpo
    endtry
endfunction

command! -bar WriteBackup :call <SID>WriteBackup()

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
