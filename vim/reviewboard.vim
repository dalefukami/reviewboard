
let s:rb_buffer_id = -1
let g:rb_window_height = 8
let s:rb_buffer_name       = '[ReviewBoard]'

function! s:RBWindowOpen() range

    " Save the current buffer number.
    let s:rb_buffer_last       = bufnr('%')
    let s:rb_buffer_last_winnr = winnr()
    let l:win_size = g:yankring_window_height

    if bufwinnr(s:rb_buffer_id) == -1
        " Special consideration was involved with these sequence
        " of commands.  
        "     First, split the current buffer.
        "     Second, edit a new file.
        "     Third record the buffer number.
        " If a different sequence is followed when the yankring
        " buffer is closed, Vim's alternate buffer is the yanking
        " instead of the original buffer before the yankring 
        " was shown.
        let cmd_mod = ''
        if v:version >= 700
            let cmd_mod = 'keepalt '
        endif
        exec 'silent! ' . cmd_mod . 'botright' . ' ' . l:win_size . 'split ' 

        " Using :e and hide prevents the alternate buffer
        " from being changed.
        exec ":e " . escape(s:rb_buffer_name, ' ')
        " Save buffer id
        let s:rb_buffer_id = bufnr('%') + 0
    else
        " If the buffer is visible, switch to it
        exec bufwinnr(s:rb_buffer_id) . "wincmd w"
    endif

    " Mark the buffer as scratch
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile
    setlocal nowrap
    setlocal nonumber
    setlocal nobuflisted
    setlocal noreadonly
    setlocal modifiable

    " Setup buffer variables
    let b:line_number = a:firstline
    let b:num_lines = a:lastline - a:firstline + 1

    nnoremap <buffer> <silent> <Leader>s :call <SID>RBSaveComment()<CR>
endfunction

function! s:RBSaveComment()
    let l:content = join(getline(0,'$'),"\n")
    echo l:content
    echo system( "/home/dale/projects/review_board/bin/reviewboard.rb comment  -q 494 -r 761 -l ".b:line_number." -c \"".l:content."\" -n ".b:num_lines." -f 25083 -d 1" )
endfunction

command! -range -nargs=? RBWindowOpen  <line1>,<line2>call s:RBWindowOpen(<args>)
map <Leader>rb :RBWindowOpen<CR>


sign define comment text=cc texthl=Search

function! s:RBtest()
    let l:diff_json = system("/home/dale/projects/review_board/bin/reviewboard.rb diff -q 494")
    let b:comments = eval(l:diff_json)
    for l:comment in b:comments
        echo l:comment
        exec ":sign place ".l:comment['id']." line=".l:comment['first_line']." name=comment file=" .expand("%:p")
    endfor
endfunction

command! RBtest  call s:RBtest()
map <Leader>a :RBtest<CR>
