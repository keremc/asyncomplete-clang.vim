function! asyncomplete#sources#clang#get_source_options(opts) abort
    return extend({
        \     'refresh_pattern': '\k\+$'
        \ }, a:opts)
endfunction

function! asyncomplete#sources#clang#completor(opts, ctx) abort
    let config = s:get_config(a:opts)

    let clang_path = config['global']['clang_path']
    if !executable(clang_path)
        return
    endif

    let clang_args = s:get_clang_args(a:ctx, config)

    let tmp_file = s:write_to_tmp_file()
    let start_column = s:get_start_column(a:ctx)

    let cmd = [clang_path] + clang_args + ['-fsyntax-only',
        \ '-Xclang', '-code-completion-macros', '-Xclang', '-code-completion-at',
        \ '-Xclang', printf('%s:%d:%d', tmp_file, a:ctx['lnum'], start_column), tmp_file]

    let matches = []

    call async#job#start(cmd, {
        \     'on_stdout': function('s:handler', [a:opts, a:ctx, start_column, matches]),
        \     'on_exit': function('s:handler', [a:opts, a:ctx, start_column, matches])
        \ })
endfunction

function! s:handler(opts, ctx, start_column, matches, job_id, data, event) abort
    if a:event == 'stdout'
        for line in a:data
            let completion_item = matchstr(line, '^COMPLETION: \zs.*\ze :')
            if empty(completion_item)
                continue
            endif

            call add(a:matches, {
                \ 'word': completion_item, 'menu': printf('[%s]', a:opts['name']),
                \ 'dup': 0, 'icase': 1})
        endfor
    elseif a:event == 'exit'
        call asyncomplete#complete(a:opts['name'], a:ctx, a:start_column, a:matches)
    endif
endfunction

function! s:get_config(opts) abort
    let global_config = {
        \     'clang_path': 'clang',
        \     'clang_args': {
        \         'common': [],
        \         'c': [],
        \         'c++': []
        \     },
        \     'langs': {
        \         'c++': ['cpp']
        \     }
        \ }
    call s:update_dict(global_config, get(a:opts, 'config', {}))

    let buffer_config = get(b:, 'asyncomplete_clang_config', {})

    return {'global': global_config, 'buffer': buffer_config}
endfunction

function! s:get_clang_args(ctx, config) abort
    let args = []

    let lang = s:get_lang(a:ctx, a:config)
    call extend(args, ['-x', lang])

    let buffer_config = a:config['buffer']
    let clang_complete_file = findfile('.clang_complete', '.;')
    let global_clang_args = a:config['global']['clang_args']

    if has_key(buffer_config, 'clang_args')
        call extend(args, buffer_config['clang_args'])
    elseif !empty(clang_complete_file)
        let working_dir = fnamemodify(clang_complete_file, ':p:h')
        call extend(args, ['-working-directory',  working_dir])
        call extend(args, readfile(clang_complete_file))
    else
        call extend(args, global_clang_args['common'] + global_clang_args[lang])
    endif

    return args
endfunction

function! s:write_to_tmp_file() abort
    let file = tempname()
    call writefile(getline(1, '$'), file)
    return file
endfunction

function! s:get_start_column(ctx)
    let cur_column = a:ctx['col']
    let text_length = len(matchstr(a:ctx['typed'], '\k\+$'))
    return cur_column - text_length
endfunction

function! s:update_dict(dict, override)
    for key in keys(a:override)
        if type(a:override[key]) == v:t_dict &&
            \ has_key(a:dict, key) && type(a:dict[key]) == v:t_dict
            call s:update_dict(a:dict[key], a:override[key])
        else
            let a:dict[key] = deepcopy(a:override[key])
        endif
    endfor
endfunction

function! s:get_lang(ctx, config)
    let buffer_config = a:config['buffer']
    if has_key(buffer_config, 'lang')
        return buffer_config['lang']
    endif

    let file_type = a:ctx['filetype']
    let langs = a:config['global']['langs']
    for key in keys(langs)
        if index(langs[key], file_type) >= 0
            return key
        endif
    endfor
    return file_type
endfunction
