let s:actions = {
  \ 'pop': 'git stash pop ',
  \ 'drop': 'git stash drop ',
  \ 'push': 'git stash push -m ',
  \ 'apply': 'git stash apply ', }

let s:stash_actions = get(g:, 'fuzzy_stash_actions', { 'ctrl-d': 'drop', 'ctrl-a': 'pop', 'ctrl-p': 'apply', 'ctrl-s': 'push' })

function! s:get_git_root()
    let root = split(system('git rev-parse --show-toplevel'), '\n')[0]
    return v:shell_error ? '' : root
endfunction

function! s:stash_sink(lines)

    let action = get(s:stash_actions, a:lines[1])
    let cmd = get(s:actions, action, 'echo ')

    if len(a:lines) < 3
        if cmd != s:actions.push
            return
        endif
    endif

    if cmd == s:actions.drop
        for idx in range(len(a:lines) - 1, 2, -1)
            let stash = matchstr(a:lines[idx], 'stash@{[0-9]\+}')
            call system(cmd.stash)
        endfor
    else
        if cmd == s:actions.push
            call s:create_stash(a:lines[0])
        else
            let stash = matchstr(a:lines[2], 'stash@{[0-9]\+}')
            call system(cmd.stash)
            checktime
        endif
    endif
endfunction

function! s:create_stash(...)
    let root = s:get_git_root()
    if empty(root)
        return 0
    endif
    if len(a:000) > 0
        let name = '-m "'.a:1.'"'
    else
        let name = '' 
    endif
    let str = split(system('git stash push '.name), '\n')[0]
    checktime
    redraw
    echo str
endfunction

function! fuzzystash#list_stash(...)
    let root = s:get_git_root()
    if empty(root)
        return 0
    endif
    let source = 'git stash list'
    let expect_keys = join(keys(s:stash_actions), ',')
    let actions = s:translate_actions(s:stash_actions)
    let options = {
    \ 'source': source,
    \ 'sink*': function('s:stash_sink'),
    \ 'options': ['--ansi', '--multi', '--tiebreak=index',
    \   '--print-query', '--inline-info', '--prompt', 'Stashes> ', '--header',
    \   ':: ' . actions, '--expect='.expect_keys,
    \   '--preview', 'grep -o "stash@{[0-9]\+}" <<< {} | xargs git stash show --format=format: -p --color=always']
    \ }
    return fzf#run(fzf#wrap("Test", options, 0))
endfunction

function! s:translate_actions(action_dict)
    return join(map(items(a:action_dict), 'toupper(v:val[0]) . " to " . v:val[1]'), ', ')
endfunction


