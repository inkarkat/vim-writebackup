" writebackup.vim: Write backups of current file with date file extension.  
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 
"   - writebackup.vim autoload script. 
"
" Copyright: (C) 2007-2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
let s:version = 300
" REVISION	DATE		REMARKS 
"   3.00.018	14-Feb-2012	ENH: New default "redate" for
"				g:WriteBackup_AvoidIdenticalBackups that renames
"				an identical backup from an earlier date to be
"				the first backup of today. 
"   2.10.017	27-May-2009	Changes in the autoload script; just bumped
"				version number here. 
"   2.00.016	22-Feb-2009	Added [!] to WriteBackup command. 
"   2.00.015	21-Feb-2009	Added g:WriteBackup_AvoidIdenticalBackups
"				configuration. 
"   2.00.014	17-Feb-2009	Moved functions from plugin to separate autoload
"				script. 
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
"				Now requiring Vim 7.0 or later, because it's
"				using lists. 
"				BF: Special ex command characters ' \%#' must be
"				escaped for ':w' command. 
"   1.00.004	07-Mar-2007	Added documentation. 
"	0.03	06-Dec-2006	Factored out WriteBackup_GetBackupFilename() to
"				use in :WriteBackupOfSavedOriginal. 
"	0.02	14-May-2004	Avoid that the written file becomes the
"				alternate file (via set cpo-=A)
"	0.01	15-Nov-2002	file creation

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_writebackup') || (v:version < 700)
    finish
endif
let g:loaded_writebackup = s:version
" Note: We cannot check for the existence of the writebackupVersionControl
" plugin here, as it will only be sourced _after_ this plugin. 

"- configuration --------------------------------------------------------------
if ! exists('g:WriteBackup_BackupDir')
    let g:WriteBackup_BackupDir = '.'
endif

if ! exists('g:WriteBackup_AvoidIdenticalBackups')
    let g:WriteBackup_AvoidIdenticalBackups = 'redate'
endif

"- commands -------------------------------------------------------------------
command! -bar -bang WriteBackup call writebackup#WriteBackup(<bang>0)

unlet s:version
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
