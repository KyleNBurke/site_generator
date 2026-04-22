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
		^Sub_Sup_Expr,
		^Operator_Expr,
		^Operator_Frac_Expr,
		^Operator_Sqrt_Expr,
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

Sub_Sup_Expr :: struct {
	using expr: Expr,
	base_expr: ^Expr,
    sub_expr: ^Expr,
	super_expr: ^Expr,
}

Operator_Expr :: struct {
	using expr: Expr,
	op: string,
	right_space: bool,
}

Operator_Frac_Expr :: struct {
	using expr: Expr,
	top_exprs: []^Expr,
	bottom_exprs: []^Expr,
}

Operator_Sqrt_Expr :: struct {
	using expr: Expr,
	sqrt_exprs: []^Expr,
}

Row_Expr :: struct {
	using expr: Expr,
	exprs: []^Expr,
}
