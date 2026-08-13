source ~/.vim/vundles.vim

" encoding dectection
set fileencodings=utf-8,gb2312,gb18030,gbk,ucs-bom,cp936,latin1

" add cpp tags
" set tags+=~/.vim/cpp_tags

" enable filetype dectection and ft specific plugin/indent
"filetype plugin indent on

set nobackup
set noswapfile
set noundofile

" enable syntax hightlight and completion
syntax on

" Vim UI
"--------
" color scheme
set background=dark
colorscheme molokai
" colorscheme blue

" highlight current line
au WinLeave * set nocursorline nocursorcolumn
au WinEnter * set cursorline cursorcolumn
set cursorline cursorcolumn

set colorcolumn=80

" search
set incsearch
set hlsearch
"set highlight 	                                                  " conflict with highlight current line
set ignorecase
set smartcase

" editor settings
set history=1000
set nocompatible
set nofoldenable                                                  " disable folding"
set confirm                                                       " prompt when existing from an unsaved file
set backspace=indent,eol,start                                    " More powerful backspacing
set t_Co=256                                                      " Explicitly tell vim that the terminal has 256 colors "
"set mouse=a                                                       " use mouse in all modes
set report=0                                                      " always report number of lines changed                "
set nowrap                                                        " dont wrap lines
set scrolloff=5                                                   " 5 lines above/below cursor when scrolling
set number                                                        " show line numbers
"set relativenumber                                                " show relativenumber
set showmatch                                                     " show matching bracket (briefly jump)
set showcmd                                                       " show typed command in status bar
set title                                                         " show file in titlebar
set laststatus=2                                                  " use 2 lines for the status bar
set matchtime=2                                                   " show matching bracket for 0.2 seconds
set directory=~/.vim/tmp                                          " move swp file to /tmp

" Default Indentation
set autoindent
set expandtab       " expand tab to space
set smartindent     " indent when
set tabstop=2       " tab width
set softtabstop=2   " backspace
set shiftwidth=2    " indent width
" set textwidth=79
" set smarttab      " insert tabs on the start of a line according to shiftwidth, not tabstop

" iTerm2 Cursor settings
let &t_SI = "\<Esc>]50;CursorShape=1\x7"
let &t_SR = "\<Esc>]50;CursorShape=2\x7"
let &t_EI = "\<Esc>]50;CursorShape=0\x7"

autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4 textwidth=120

" syntax support

"-----------------
" Plugin settings
"-----------------
" Rainbow parentheses for Lisp and variants
let g:rbpt_colorpairs = [
    \ ['brown',       'RoyalBlue3'],
    \ ['Darkblue',    'SeaGreen3'],
    \ ['darkgray',    'DarkOrchid3'],
    \ ['darkgreen',   'firebrick3'],
    \ ['darkcyan',    'RoyalBlue3'],
    \ ['darkred',     'SeaGreen3'],
    \ ['darkmagenta', 'DarkOrchid3'],
    \ ['brown',       'firebrick3'],
    \ ['gray',        'RoyalBlue3'],
    \ ['black',       'SeaGreen3'],
    \ ['darkmagenta', 'DarkOrchid3'],
    \ ['Darkblue',    'firebrick3'],
    \ ['darkgreen',   'RoyalBlue3'],
    \ ['darkcyan',    'SeaGreen3'],
    \ ['darkred',     'DarkOrchid3'],
    \ ['red',         'firebrick3'],
    \ ]
let g:rbpt_max = 16
autocmd Syntax lisp,scheme,clojure,racket RainbowParenthesesToggle

" tabbar
"let g:Tb_MaxSize = 2
"let g:Tb_TabWrap = 1

hi Tb_Normal guifg=white ctermfg=white
hi Tb_Changed guifg=green ctermfg=green
hi Tb_VisibleNormal ctermbg=252 ctermfg=235
hi Tb_VisibleChanged guifg=green ctermbg=252 ctermfg=white

" easy-motion
"let g:EasyMotion_leader_key = '<Leader>'

" Tagbar
let g:tagbar_left=1
let g:tagbar_width=30
let g:tagbar_autofocus = 1
let g:tagbar_sort = 0
let g:tagbar_compact = 1
" tag for markdown
let g:tagbar_type_markdown = {
	\ 'ctagstype' : 'markdown',
	\ 'kinds' : [
		\ 'h:Heading_L1',
		\ 'i:Heading_L2',
		\ 'k:Heading_L3'
	\ ]
\ }

" Nerd Tree
let NERDChristmasTree=0
let NERDTreeWinSize=40
let NERDTreeChDirMode=2
let NERDTreeIgnore=['\~$', '\.pyc$', '\.swp$']
" let NERDTreeSortOrder=['^__\.py$', '\/$', '*', '\.swp$',  '\~$']
let NERDTreeShowBookmarks=1
let NERDTreeWinPos = "right"

" nerdcommenter
let NERDSpaceDelims=1
" nmap <D-/> :NERDComToggleComment<cr>
let NERDCompactSexyComs=1
let NERDTreeShowHidden=1

:imap jj <Esc>
" powerline
"let g:Powerline_symbols = 'fancy'

" NeoComplCache
" let g:neocomplcache_enable_at_startup=1
" let g:neoComplcache_disableautocomplete=1
"let g:neocomplcache_enable_underbar_completion = 1
"let g:neocomplcache_enable_camel_case_completion = 1
" let g:neocomplcache_enable_smart_case=1
" let g:neocomplcache_min_syntax_length = 3
" let g:neocomplcache_lock_buffer_name_pattern = '\*ku\*'
" set completeopt-=preview

"imap <C-k> <Plug>(neocomplcache_snippets_force_expand)
"smap <C-k> <Plug>(neocomplcache_snippets_force_expand)
"imap <C-l> <Plug>(neocomplcache_snippets_force_jump)
"smap <C-l> <Plug>(neocomplcache_snippets_force_jump)

" Enable omni completion.
" autocmd FileType markdown setlocal omnifunc=htmlcomplete#CompleteTags
" autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
" autocmd FileType c setlocal omnifunc=ccomplete#Complete
" if !exists('g:neocomplcache_omni_patterns')
"   let g:neocomplcache_omni_patterns = {}
" endif
" let g:neocomplcache_omni_patterns.erlang = '[a-zA-Z]\|:'

" SuperTab
" let g:SuperTabDefultCompletionType='context'
let g:SuperTabDefaultCompletionType = '<C-X><C-U>'
let g:SuperTabRetainCompletionType=2

" ctrlp
set wildignore+=*/tmp/*,*.so,*.o,*.a,*.obj,*.swp,*.zip,*.pyc,*.pyo,*.class,.DS_Store  " MacOSX/Linux
let g:ctrlp_custom_ignore = '\.git$\|\.hg$\|\.svn$'

" Keybindings for plugin toggle
nnoremap <F2> :set invpaste paste?<CR>
set pastetoggle=<F2>
nmap <F5> :TagbarToggle<cr>
nmap <C-n> :NERDTreeToggle<cr>
"nmap <F3> :GundoToggle<cr>
"nmap <F4> :IndentGuidesToggle<cr>
"nmap  <D-/> :
"nnoremap <leader>a :Ack
"nnoremap <leader>v V`]

" Useful Functions
"------------------
" easier navigation between split windows
"nnoremap <c-j> <c-w>j
"nnoremap <c-k> <c-w>k
"nnoremap <c-h> <c-w>h
"nnoremap <c-l> <c-w>l

" When editing a file, always jump to the last cursor position
"autocmd BufReadPost *
"      \ if ! exists("g:leave_my_cursor_position_alone") |
"      \     if line("'\"") > 0 && line ("'\"") <= line("$") |
"      \         exe "normal g'\"" |
"      \     endif |
"      \ endif

" w!! to sudo & write a file
"cmap w!! %!sudo tee >/dev/null %

" Quickly edit/reload the vimrc file
"nmap <silent> <leader>ev :e $MYVIMRC<CR>
"nmap <silent> <leader>sv :so $MYVIMRC<CR>

" sublime key bindings
"nmap <D-]> >>
"nmap <D-[> <<
"vmap <D-[> <gv
"vmap <D-]> >gv

" eggcache vim
nnoremap ; :
":command W w
":command WQ wq
":command Wq wq
":command Q q
":command Qa qa
":command QA qa

" In insert or command mode, move normally by using Ctrl
" inoremap <C-h> <Left>
" inoremap <C-j> <Down>
" inoremap <C-k> <Up>
" inoremap <C-l> <Right>
" cnoremap <C-h> <Left>
" cnoremap <C-j> <Down>
" cnoremap <C-k> <Up>
" cnoremap <C-l> <Right>
" 
" for macvim
"if has("gui_running")
"    "set go=aAce  " remove toolbar
"    set transparency=2
"    ""不全屏为set nofu
"    set nofu
"    set guifont=Monaco:h13
"    set showtabline=2
"    set columns=140
"    set lines=40
"    set guioptions=mr       "c去掉"
"    set guioptions=         " 隐藏全部
"    set guioptions+=m       " 隐藏菜单栏
"    set guioptions-=T       " 隐藏工具栏
"    set guioptions-=L       " 隐藏左侧滚动条
"    "set guioptions+=r      " 隐藏右侧滚动条
"    "set guioptions-=b      " 隐藏底部滚动条
"    "set showtabline-=0     " 隐藏Tab栏
"    "noremap <D-M-Left> :tabprevious<cr>
"    "noremap <D-M-Right> :tabnext<cr>
"    "map <D-1> 1gt
"    "map <D-2> 2gt
"    "map <D-3> 3gt
"    "map <D-4> 4gt
"    "map <D-5> 5gt
"    "map <D-6> 6gt
"    "map <D-7> 7gt
"    "map <D-8> 8gt
"    "map <D-9> 9gt
"    "map <D-0> :tablast<CR>
"endif

set listchars=eol:¬,space:·,tab:-▸,trail:·
"set listchars=tab:!·,trail:·
set list

" vimdiff diffget
map <Leader>1 :diffget LOCAL<CR>
map <Leader>2 :diffget BASE<CR>
map <Leader>3 :diffget REMOTE<CR>

"clang-format

"function FormatFile()
"  let l:lines="all"
"  if has('python')
"    pyf /usr/share/clang/clang-format-12/clang-format.py
"  elseif has('python3')
"    py3f /usr/share/clang/clang-format-12/clang-format.py
"
"  endif
"endfunction
"map <C-K> :call FormatFile()<cr>

"folding
:set foldenable
:set foldmethod=indent
:set foldlevel=99

