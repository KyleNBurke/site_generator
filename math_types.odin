package main

make_expr :: proc($T: typeid) -> ^T {
	expr := new(T)
	expr.variant = expr
	return expr
}

Expr :: struct {
    variant: union {
        ^Ident_Expr,
		^String_Expr,
		^Number_Expr,
        ^Superscript_Expr,
        ^Subscript_Expr,
		^Operator_Expr,
		^Row_Expr,
    }
}

Ident_Expr :: struct {
    using expr: Expr,
    str: string,
}

String_Expr :: struct {
    using expr: Expr,
    str: string,
}

Number_Expr :: struct {
    using expr: Expr,
    str: string,
}

Superscript_Expr :: struct {
    using expr: Expr,
    base_expr: ^Expr,
    super_expr: ^Expr,
}

Subscript_Expr :: struct {
    using expr: Expr,
    base_expr: ^Expr,
    sub_expr: ^Expr,
}

Operator_Expr :: struct {
	using expr: Expr,
	op: u8,
}

Row_Expr :: struct {
	using expr: Expr,
	exprs: []^Expr,
}
