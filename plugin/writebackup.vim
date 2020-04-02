" writebackup.vim: Write backups of current file with date file extension.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingo-library.vim plugin
"
" Copyright: (C) 2007-2020 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
let s:version = 300

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

if ! exists('g:WriteBackup_ExclusionPredicates')
    let g:WriteBackup_ExclusionPredicates = []
endif


"- commands -------------------------------------------------------------------

command! -bar -bang WriteBackup if ! writebackup#WriteBackup(<bang>0) | echoerr ingo#err#Get() | endif

unlet s:version
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
