package main

make_expr :: proc($T: typeid) -> ^T {
	expr := new(T)
	expr.variant = expr
	return expr
}

Expr :: struct {
    variant: union {
		^Expr_List,
        ^Ident_Expr,
		^String_Expr,
		^Number_Expr,
        ^Superscript_Expr,
        ^Subscript_Expr,
		^Sub_Sup_Expr,
		^Operator_Expr,
		^Operator_Frac_Expr,
		^Operator_Sqrt_Expr,
		^Curly_Braced_Expr,
		^Table_Expr,
		^Aligned_Table_Expr,
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
	top_expr: ^Curly_Braced_Expr,
	bottom_expr: ^Curly_Braced_Expr,
}

Operator_Sqrt_Expr :: struct {
	using expr: Expr,
	sqrt_expr: ^Expr,
}

// Expressions NOT inside curly braces
Expr_List :: struct {
	using expr: Expr,
	exprs: [dynamic]^Expr,
}

Curly_Braced_Expr :: struct {
	using expr: Expr,
	expr_list: ^Expr_List
}

Table_Expr :: struct {
	using expr: Expr,
	rows: []^Expr,
}

Aligned_Table_Expr :: struct {
	using expr: Expr,
	rows: [dynamic][2]^Expr,
}