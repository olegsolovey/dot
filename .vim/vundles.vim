set nocompatible               " be iMproved
filetype off                   " required!

set rtp+=~/.vim/bundle/Vundle.vim/
call vundle#rc()

" let Vundle manage Vundle
" required!
Plugin 'gmarik/vundle'

" Code Completions
" Plugin 'Shougo/neocomplcache'
" Plugin 'Raimondi/delimitMate'
" Plugin 'ervandew/supertab'
"
" Code Format https://github.com/google/vim-codefmt
" Add maktaba and codefmt to the runtimepath.
" (The latter must be installed before it can be used.)
Plugin 'google/vim-maktaba'
Plugin 'google/vim-codefmt'
" Also add Glaive, which is used to configure codefmt's maktaba flags. See
" `:help :Glaive` for usage.
Plugin 'google/vim-glaive'

" snippets
"Plugin 'garbas/vim-snipmate'
"Plugin 'honza/vim-snippets'
" snipmate dependencies
Plugin 'MarcWeber/vim-addon-mw-utils'
" Plugin 'tomtom/tlib_vim'

" Fast navigation
Plugin 'jwhitley/vim-matchit'
Plugin 'Lokaltog/vim-easymotion'

" Fast editing
" Plugin 'tpope/vim-surround'
Plugin 'scrooloose/nerdcommenter'
Plugin 'sjl/gundo.vim'
"Plugin 'godlygeek/tabular'
" Plugin 'nathanaelkane/vim-indent-guides'

" IDE features
Plugin 'scrooloose/nerdtree'
"Plugin 'humiaozuzu/TabBar'
Plugin 'majutsushi/tagbar'
Plugin 'mileszs/ack.vim'
Plugin 'kien/ctrlp.vim'
"Plugin 'tpope/vim-fugitive'
Plugin 'Lokaltog/vim-powerline'
Plugin 'scrooloose/syntastic'
Plugin 'bronson/vim-trailing-whitespace'
"Plugin 'ycm-core/YouCompleteMe'

" Other Utils
" Plugin 'humiaozuzu/fcitx-status'
"Plugin 'nvie/vim-togglemouse'

" Syntax/Indent for language enhancement
" markup language
Plugin 'tpope/vim-markdown'
" Plugin 'timcharper/textile.vim'
" Golang
" Plugin 'fatih/vim-go'

" FPs
Plugin 'kien/rainbow_parentheses.vim'
" Plugin 'wlangstroth/vim-racket'
" Plugin 'vim-scripts/VimClojure'
" Plugin 'rosstimson/scala-vim-support'

" Color Schemes
Plugin 'altercation/vim-colors-solarized'
Plugin 'tomasr/molokai'
Plugin 'chriskempson/vim-tomorrow-theme'

filetype plugin indent on     " required!

call vundle#end()
" the glaive#Install() should go after the "call vundle#end()"
call glaive#Install()
" Optional: Enable codefmt's default mappings on the <Leader>= prefix.
Glaive codefmt plugin[mappings]
Glaive codefmt google_java_executable="java -jar /path/to/google-java-format-VERSION-all-deps.jar"
