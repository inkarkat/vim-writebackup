WRITE BACKUP
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

This is a poor man's revision control system, a primitive alternative to CVS,
RCS, Subversion, etc., which works with no additional software and almost any
file system.
The :WriteBackup command writes subsequent backups of the current file with a
'current date + counter' file extension (format '.YYYYMMDD[a-z]'). The first
backup of a day has letter 'a' appended, the next 'b', and so on. (So that a
file can be backed up up to 26 times on any given day.)

By default, backups are created in the same directory as the original file,
but they can also be placed in a directory relative to the original file, or
in one common backup directory for all files (similar to Vim's 'backupdir'
option), or even in a file-specific location that is determined via a
user-provided callback function.

### SEE ALSO

- The writebackupVersionControl.vim plugin ([vimscript #1829](http://www.vim.org/scripts/script.php?script_id=1829)) complements
  this script with additional commands and enhances the :WriteBackup command
  with more checks, but is not required.
- The writebackupToAdjacentDir.vim plugin ([vimscript #3107](http://www.vim.org/scripts/script.php?script_id=3107)) implements a
  WriteBackup-dynamic-backupdir configuration that puts the backup files in
  an adjacent backup directory if one exists. This helps where the backups
  cannot be placed into the same directory.
- The writebackupAutomator.vim plugin ([vimscript #3940](http://www.vim.org/scripts/script.php?script_id=3940)) automatically writes
  a backup on a day's first write of a file that was backed up in the past,
  but not yet today. It can be your safety net when you forget to make a
  backup.

USAGE
------------------------------------------------------------------------------

    :WriteBackup[!]
                            Write the whole current buffer to the next available
                            backup file with a '.YYYYMMDD[a-z]' file extension.
                            If the last backup is identical with the current
                            buffer contents, no (redundant) backup is written.
                            With [!], creation of a new backup file is forced:
                            - even if the last backup is identical
                            - even when no more backup versions (for this day) are
                              available (the last '.YYYYMMDDz' backup gets
                              overwritten, even if it is readonly)
                            - even if writing of backups is disallowed by a
                              configured g:WriteBackup_ExclusionPredicates

    PS: In addition to this Vim plugin, I also provide the basic writebackup
    functionality outside of Vim as VBScript and Bash Shell script versions at
    http://ingo-karkat.de/downloads/tools/writebackup/index.html

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-writebackup
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim writebackup*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.012 or
  higher.
- The writebackupVersionControl.vim plugin ([vimscript #1829](http://www.vim.org/scripts/script.php?script_id=1829)) complements
  this script with additional commands and enhances the :WriteBackup command
  with more checks, but is not required.

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

To put backups into another directory, specify a backup directory via

    let g:WriteBackup_BackupDir = 'D:\backups'

Please note that this setting may result in name clashes when backing up files
with the same name from different directories!

A directory starting with './' or '../' (or the backslashed-variants '.\\' for
MS-DOS et al.) puts the backup file relative to where the backed-up file is.
The leading '.' is replaced with the path name of the current file:

    let g:WriteBackup_BackupDir = './backups'

Backup creation will fail if the backup directory does not exist, the
directory will NOT be created automatically!

If you want to automatically create a non-existing backup directory,
dynamically determine the backup directory based on the current filespec or
any other changing circumstances, you can set a custom callback function:

    function MyResolveBackupDir(originalFilespec, isQueryOnly)
        ...
        return backupDirspec
    endfunction
    let g:WriteBackup_BackupDir = function('MyResolveBackupDir')

This function will be invoked each time a backup is about to be written. The
function must accept one String argument that represents the filespec of the
original file (the filespec can be relative or absolute, like the output of
expand('%')), and one Number that represents a boolean flag whether this is
just a query (no backup is about to be written, so don't cause any permanent
side effects).
It must return a String representing the backup dirspec (again either relative
or absolute, '.' for current directory, please no trailing path separator).
Throw an exception if you want to abort the backup. If the exception starts
with 'WriteBackup:', the rest of the exception text will be nicely printed as
the error text to the user. To just forbid backup creation for certain files,
use g:WriteBackup\_ExclusionPredicates instead.

Remember that because of the alphabetic numbering, it doesn't make much sense
if the backup directory changes for subsequent backups of the same file. Use
this functionality to adapt the backup location based on filespec, file type,
availability of a backup medium, etc., or to inject additional side effects
like creating backup directories, pruning old backups, etc.

You can override this global setting for specific buffers via a buffer-scoped
variable, which can be set by an autocmd, ftplugin, or manually:

    let b:WriteBackup_BackupDir = 'X:\special\backup\folder'

If the writebackupVersionControl plugin is installed, no backup is written if
there is an identical predecessor, so you don't need to remember whether
you've already backed up the current file; no redundant backups will be
created.
If you don't like this check, turn it off via:

    let g:WriteBackup_AvoidIdenticalBackups = 0

It occasionally happens that an identical backup is kept lying around, e.g.
when reverting to the backup without removing it. Since that backup would
misleadingly date the next change much earlier than it actually happened,
writebackup automatically renames the earlier backup if it would be identical
to the first backup created today.
If you don't want such an automatic rename and instead get the "is already
backed up" error, turn off redate via:

    let g:WriteBackup_AvoidIdenticalBackups = 1

This reinstates the old behavior of writebackup versions &lt; 3.00.

To disallow a backup for certain files, you can define a List of expressions
or Funcrefs that are evaluated; if one returns 1 (or a non-empty String, in
which case this will be the error message), backup of the buffer will be
skipped (unless :WriteBackup! is used).

    let g:writebackup_ExclusionPredicates = [
    \   'expand("%:e") ==? "bak"',
    \   function('ExcludeScratchFiles')
    \]

In case you already have other custom Vim commands starting with W, you can
define a shorter command alias ':W' in your vimrc to save some keystrokes. I
like the parallelism between ':w' for a normal write and ':W' for a backup
write.

    command -bar -bang W :WriteBackup<bang>

Backups done in the late-night hours after midnight (by default until 03:00,
configurable via the $BEDTIME\_HOUR environment variable) will continue to use
the previous day's timestamp (so that the sequential numbering correctly
indicates the continuous editing).

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-writebackup/issues or email (address below).

HISTORY
------------------------------------------------------------------------------

##### 3.20    RELEASEME
- ENH: Backups done in the late-night hours after midnight (by default until
  03:00, configurable via the $BEDTIME\_HOUR environment variable) will
  continue to use the previous day's timestamp (so that the sequential
  numbering correctly indicates the continuous editing).

##### 3.10    02-Apr-2020
- ENH: Add g:WriteBackup\_ExclusionPredicates to disallow writing of backups
  (unless it is forced via :WriteBackup!), e.g. when another (proper) revision
  control system (like Git) is used.

##### 3.01    29-Jan-2014
- :WriteBackup now aborts on error.
- Add dependency to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)).

__You need to separately
  install ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.012 (or higher)!__

##### 3.00    16-Feb-2012
- ENH: New default "redate" for g:WriteBackup\_AvoidIdenticalBackups that renames
an identical backup from an earlier date to be the first backup of today.

##### 2.11    23-Feb-2010 (unreleased)
- Using :keepalt instead of a temporary :set cpo-=A.

##### 2.10    27-May-2009
- Replaced simple filespec escaping with built-in fnameescape() function (or
emulation for Vim 7.0 / 7.1) via escapings.vim wrapper.

##### 2.00    22-Feb-2009
- Using separate autoload script to help speed up Vim startup. This is an
  incompatible change that also requires the corresponding
  writebackupVersionControl plugin version.

__PLEASE UPDATE
  writebackupVersionControl ([vimscript #1829](http://www.vim.org/scripts/script.php?script_id=1829)), too, if you're using it__
- ENH: Disallowing backup of backup file if the writebackupVersionControl
  plugin is installed.
- ENH: No backup is written if there is an identical previous backup. This
  requires the writebackupVersionControl plugin and can be configured via
  g:WriteBackup\_AvoidIdenticalBackups.

##### 1.31    16-Feb-2009
- Split off documentation into separate help file. Now packaging as VimBall.

##### 1.30    13-Feb-2009
- ENH: The backup directory can now be determined dynamically through a
  callback function.
- Renamed configuration variable from g:writebackup\_BackupDir to
  g:WriteBackup\_BackupDir.

__PLEASE UPDATE YOUR CONFIGURATION__
- BF: Now also allowing relative backup dir in an upper directory (i.e.
  g:WriteBackup\_BackupDir starting with '../'.
- BF: Unnamed buffers were backed up as '.YYYYMMDDa'.
- Now setting v:errmsg on errors and using ErrorMsg instead of Error highlight
  group.

##### 1.20    18-Sep-2007
- ENH: Added support for writing backup files into a different directory
  (either one static backup dir or relative to the original file) via
  g:writebackup\_BackupDir configuration, as suggested by Vincent DiCarlo.
- Now requiring Vim 7.0 or later, because it's using lists.
- BF: Special Ex command characters ' \\%#' must be escaped for ':w' command.

##### 1.00    07-Mar-2007
- Added documentation. First release.

##### 0.01    15-Nov-2002
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2007-2021 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;
