# asyncomplete-clang.vim

**NOT READY FOR GENERAL USE!**

Provide C, C++, Objective-C and Objective-C++ support for [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim).

## Requirements

* Vim 8 or Neovim
* Clang
* [async.vim](https://github.com/prabirshrestha/async.vim) and asyncomplete.vim

## Installation

* Install this plugin with your preferred Vim plugin manager.
* Append your Vim configuration file:
```vim
autocmd User asyncomplete_setup call asyncomplete#register_source(
    \ asyncomplete#sources#clang#get_source_options())
```

## Configuration

This plugin can be further configured by passing a dictionary to `asyncomplete#sources#clang#get_source_options()` like this:
```vim
autocmd User asyncomplete_setup call asyncomplete#register_source(
    \ asyncomplete#sources#clang#get_source_options({
    \     'config': {
    \         'clang_path': '/opt/llvm/bin/clang',
    \         'clang_args': {
    \             'default': ['-I/opt/llvm/include'],
    \             'cpp': ['-std=c++11', '-I/opt/llvm/include']
    \         }
    \     }
    \ }))
```

| Option | Explanation |
|---|---|
| config.clang_path | Path to the `clang` binary. If `clang` cannot be found in `PATH`, you must specify this manually. |
| config.clang_args | Map where the key is a file type name and its value is a list of Clang arguments to be used with that file type. If there is no entry for a particular file type, `'default'` is used instead. |

### .clang_complete

Should you wish to pass extra arguments to Clang, you can create a file named `.clang_complete` in the root directory of your project. Each line in this file will be treated as a single argument and the directory in which `.clang_complete` resides will be used as the working directory (for Clang).

Example:
```
-std=c++14
-I/usr/local/include
-I/usr/include
```

## License

See [LICENSE](https://raw.githubusercontent.com/keremc/asyncomplete-clang.vim/master/LICENSE).
