runtime plugin/writebackup.vim

" Only source the version control extensions if we're actually testing them. 
" This way we also test that the core functionality of writebackup.vim has no
" dependencies on writebackupVersionControl.vim. 
if g:runVimTest !~# 'writebackup\d\+'
    runtime plugin/writebackupVersionControl.vim
endif

