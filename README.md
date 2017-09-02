# asyncomplete-clang.vim

**NOT READY FOR GENERAL USE!**

Provide C/C++ support for [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim).

## Installation

* Install Clang.
* Add this to your (Neo)vim configuration file:

```vim
" vim-plug
Plug 'prabirshrestha/async.vim'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'keremc/asyncomplete-clang.vim'

autocmd User asyncomplete_setup call asyncomplete#register_source(
    \ asyncomplete#sources#clang#get_source_options())
```

## Configuration

### Global

```vim
autocmd User asyncomplete_setup call asyncomplete#register_source(
    \ asyncomplete#sources#clang#get_source_options({
    \     'name': 'clang',
    \     'whitelist': ['c', 'cpp'],
    \     'completor': function('asyncomplete#sources#clang#completor'),
    \     'config': {
    \         'clang_path': 'clang',
    \         'clang_args': {
    \             'common': [],
    \             'c': [],
    \             'c++': []
    \         },
    \         'langs': {
    \             'c++': ['cpp']
    \         }
    \     }
    \ }))
```

### Buffer

```vim
autocmd FileType cpp let b:asyncomplete_clang_config = {
    \     'clang_args': [],
    \     'lang': 'c++'
    \ }
```

## License

See [LICENSE](https://raw.githubusercontent.com/keremc/asyncomplete-clang.vim/master/LICENSE).
