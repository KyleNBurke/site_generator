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
        ^Subscript_Expr,
        ^Superscript_Expr,
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

Operator_Expr :: struct {
	using expr: Expr,
	op: u8,
}

Row_Expr :: struct {
	using expr: Expr,
	row_expr: ^Expr,
}
