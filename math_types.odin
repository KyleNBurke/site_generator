package main

make_expr :: proc($T: typeid) -> ^T {
	expr := new(T)
	expr.variant = expr
	return expr
}

Expr :: struct {
    variant: union {
        ^Ident_Expr,
        ^Subscript_Expr,
        ^Superscript_Expr,
    }
}

Ident_Expr :: struct {
    using expr: Expr,
    str: string,
}

Subscript_Expr :: struct {
    using expr: Expr,
    base_expr: ^Expr,
    sub_expr: ^Expr,
}

Superscript_Expr :: struct {
    using expr: Expr,
    base_expr: ^Expr,
    super_expr: ^Expr,
}
