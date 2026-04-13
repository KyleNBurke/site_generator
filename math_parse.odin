package main

import "core:fmt"

parse_math_expr :: proc(content: string, index: ^int) -> ^Expr {
    return parse_expr(content, index)
}

parse_expr :: proc(content: string, index: ^int) -> ^Expr {
    return parse_expr_chain(content, index)
}

parse_expr_chain :: proc(content: string, index: ^int) -> ^Expr {
    expr := parse_terminal_expr(content, index)

    loop: for {
        r := content[index^]

        switch r {
        case '^':
            superscript_expr := parse_superscript_expr(content, index)
            superscript_expr.base_expr = expr

            expr = superscript_expr
        
        case:
            break loop
        }
    }

    return expr
}

parse_terminal_expr :: proc(content: string, index: ^int) -> ^Expr {
    r := content[index^]

    switch r {
    case 'a' ..= 'z':
        return parse_ident_expr(content, index)
    
    case:
        unimplemented()
    }
}

parse_superscript_expr :: proc(content: string, index: ^int) -> ^Superscript_Expr {
    index^ += 1

    // #todo: Maybe check for {} here, or maybe it should be more generic, like a paren expression in Odin?

    expr := make_expr(Superscript_Expr)
    expr.super_expr = parse_expr(content, index)
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