call vimtest#AddDependency('vim-ingo-library')

if g:runVimTest !~# 'dependency\d\+'
    " Do not yet source the plugins for the dependency tests.
    runtime plugin/writebackup.vim

    " Only source the version control extensions if we're actually testing them.
    " This way we also test that the core functionality of writebackup.vim has no
    " dependencies on writebackupVersionControl.vim.
    if g:runVimTest !~# 'writebackup\d\+'
	runtime plugin/writebackupVersionControl.vim
    endif
endif

" The tests rely on $TEMP.
if ! exists('$TEMP')
    let $TEMP = '/tmp'
endif

" Add the test directory to $PATH so that the 'setup' and 'listfiles' helper
" scripts can be executed easily.
let $PATH .= ingo#os#PathSeparator() .  expand('<sfile>:p:h')

" Set up the modifiable test data in the temporary location.
if ! vimtest#System('setup', 1)
    call vimtest#BailOut('External setup script failed with exit status ' . v:shell_error)
endif

" This evaluation function allows to compare the modified test data with the
" expected result. It is called at the end of each test.
function! ListFiles()
    new
    0r !listfiles
    call vimtest#SaveOut()
endfunction
