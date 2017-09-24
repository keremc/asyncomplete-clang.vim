# asyncomplete-clang.vim

**NOT READY FOR GENERAL USE!**

Provide Clang support for [asyncomplete.vim].

## Requirements

* Vim 8+ or Neovim
* LibClang
* Python 2
* [async.vim](https://github.com/prabirshrestha/async.vim) and [asyncomplete.vim]

## Installation

* Install this plugin with your preferred Vim plugin manager.
* Append your Vim configuration file:
```vim
autocmd User asyncomplete_setup call asyncomplete#register_source(
    \ asyncomplete#sources#clang#get_source_options())
```

## Configuration

Should you wish to pass any arguments to Clang, you can create a file named `compile_commands.json` in the root directory of your project. See [this document](https://clang.llvm.org/docs/JSONCompilationDatabase.html) for more information.

## License

See [LICENSE](https://raw.githubusercontent.com/keremc/asyncomplete-clang.vim/master/LICENSE). For files under the `bin/clang` directory, see [LICENSE.CLANG](LICENSE.CLANG).

[asyncomplete.vim]: https://github.com/prabirshrestha/asyncomplete.vim
