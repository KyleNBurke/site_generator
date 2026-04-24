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
		^Row_Expr,
		^Table_Expr,
		// ^Aligned_Exprs,
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
	top_expr: ^Expr,
	bottom_expr: ^Expr,
}

Operator_Sqrt_Expr :: struct {
	using expr: Expr,
	sqrt_expr: ^Expr,
}

// Expressions NOT inside curly braces
Expr_List :: struct {
	using expr: Expr,
	exprs: []^Expr,
}

// Expressions inside curly braces, requires the <mrow> tag
Row_Expr :: struct {
	using expr: Expr,
	// exprs: []^Expr,
	expr_list: ^Expr_List
}

Table_Expr :: struct {
	using expr: Expr,
	rows: []^Expr,
}

// Aligned_Exprs :: struct {
// 	using expr: Expr,
// 	rows: []Aligned_Exprs_Row,
// }

// Aligned_Exprs_Row :: struct {
// 	left_exprs: []^Expr,
// 	right_exprs: []^Expr,
// }