package main

import "core:fmt"

parse_math_expr :: proc(content: string, index: ^int) -> ^Expr {
    expr: ^Expr

    loop: for {
        fmt.assertf(index^ <= len(content), "Math not closed, missing $.")
        r := content[index^]
        
        switch r {
        case '$':
            index^ += 1
            break loop

        case 'a' ..= 'z':
            expr = parse_ident_expr(content, index)
        
        case:
            assert(false)
        }
    }

    return expr
}

parse_ident_expr :: proc(content: string, index: ^int) -> ^Ident_Expr {
    expr := make_expr(Ident_Expr)
    start := index^
    index^ += 1
    
    for {
        r := content[index^]

        switch r {
        case 'a' ..= 'z':
            index^ += 1
            continue
        }

        break
    }

    expr.str = content[start : index^]
    return expr
}