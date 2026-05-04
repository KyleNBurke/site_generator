package main

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
		^Root_Expr,
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

Root_Expr :: struct {
	using expr: Expr,
	degree: string,
	sqrt_expr: ^Curly_Braced_Expr,
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

make_expr :: proc($T: typeid) -> ^T {
	expr := new(T)
	expr.variant = expr
	return expr
}

parse_math_expr :: proc(text: string, pos: ^int, single_dollar: bool) -> ^Expr {
	expr := parse_expr_list(text, pos)
	
	token := parse_math_token(text, pos^)
	if single_dollar {
		assert(token.kind == .Dollar)
	} else {
		assert(token.kind == .Double_Dollar)
	}
	
	pos^ = token.end
	
	return expr
}

parse_expr_list :: proc(text: string, pos: ^int) -> ^Expr_List {
	expr_list := make_expr(Expr_List)

	for {
		expr := parse_expr_2(text, pos)
		if expr == nil do break

		append(&expr_list.exprs, expr)
	}

	return expr_list
}

parse_expr_2 :: proc(text: string, pos: ^int) -> ^Expr {
	expr := parse_terminal_expr(text, pos)

	token := parse_math_token(text, pos^)
		
	#partial switch token.kind {
	case .Carrot:
		pos^ = token.end

		superscript_expr := make_expr(Superscript_Expr)
		superscript_expr.base_expr = expr
		superscript_expr.super_expr = parse_terminal_expr(text, pos)

		expr = superscript_expr
	
	case .Underscore:
		pos^ = token.end

		sub_expr := parse_terminal_expr(text, pos)

		token = parse_math_token(text, pos^)
		if token.kind == .Carrot {
			pos^ = token.end

			super_expr := parse_terminal_expr(text, pos)

			sub_sup_expr := make_expr(Sub_Sup_Expr)
			sub_sup_expr.base_expr = expr
			sub_sup_expr.sub_expr = sub_expr
			sub_sup_expr.super_expr = super_expr

			expr = sub_sup_expr
		} else {
			subscript_expr := make_expr(Subscript_Expr)
			subscript_expr.base_expr = expr
			subscript_expr.sub_expr = sub_expr

			expr = subscript_expr
		}
	}

	return expr
}

parse_terminal_expr :: proc(text: string, pos: ^int) -> ^Expr {
	expr: ^Expr
    token := parse_math_token(text, pos^)

	#partial switch token.kind {
	case .Identifier:
		pos^ = token.end
		ident_expr := make_expr(Ident_Expr)
		ident_expr.str = text[token.start : token.end]
		expr = ident_expr
	
	case .String:
		pos^ = token.end
		string_expr := make_expr(String_Expr)
		string_expr.str = text[token.start : token.end]
		expr = string_expr
	
	case .Number:
		pos^ = token.end
		number_expr := make_expr(Number_Expr)
		number_expr.str = text[token.start : token.end]
		expr = number_expr
	
	case .Operator:
		pos^ = token.end
		op_expr := make_expr(Operator_Expr)
		op_expr.op = text[token.start : token.end]
		expr = op_expr
	
	case .Operator_Frac:
		pos^ = token.end
		expr = parse_frac_expr(text, pos)
	
	case .Operator_Sqrt:
		pos^ = token.end
		expr = parse_root_expr(text, pos)
	
	case .Open_Curly_Brace:
		pos^ = token.end
		expr = parse_curly_braced_expr(text, pos)
	
	case .Open_Bracket, .Close_Bracket:
		pos^ = token.end
		ident_expr := make_expr(Ident_Expr)
		ident_expr.str = text[token.start : token.end]
		expr = ident_expr
	
	case .Begin_Aligned:
		pos^ = token.end
		expr = parse_aligned_table_expr(text, pos)
	}

	return expr
}

parse_curly_braced_expr :: proc(text: string, pos: ^int) -> ^Curly_Braced_Expr {
	expr := make_expr(Curly_Braced_Expr)
	expr.expr_list = parse_expr_list(text, pos)

	token := parse_math_token(text, pos^)
	assert(token.kind == .Close_Curly_Brace)
	pos^ = token.end

	return expr
}

parse_frac_expr :: proc(text: string, pos: ^int) -> ^Operator_Frac_Expr {
	expr := make_expr(Operator_Frac_Expr)
	
	token := parse_math_token(text, pos^)
	assert(token.kind == .Open_Curly_Brace)
	pos^ = token.end
	expr.top_expr = parse_curly_braced_expr(text, pos)

	token = parse_math_token(text, pos^)
	assert(token.kind == .Open_Curly_Brace)
	pos^ = token.end
	expr.bottom_expr = parse_curly_braced_expr(text, pos)

	return expr
}

parse_root_expr :: proc(text: string, pos: ^int) -> ^Root_Expr {
	expr := make_expr(Root_Expr)
	
	token := parse_math_token(text, pos^)
	if token.kind == .Open_Bracket {
		pos^ = token.end

		token = parse_math_token(text, pos^)
		assert(token.kind == .Number)
		pos^ = token.end

		expr.degree = text[token.start : token.end]

		token = parse_math_token(text, pos^)
		assert(token.kind == .Close_Bracket)
		pos^ = token.end
	}

	token = parse_math_token(text, pos^)
	assert(token.kind == .Open_Curly_Brace)
	pos^ = token.end

	expr.sqrt_expr = parse_curly_braced_expr(text, pos)

	return expr
}

parse_aligned_table_expr :: proc(text: string, pos: ^int) -> ^Aligned_Table_Expr {
	expr := make_expr(Aligned_Table_Expr)
	
	for {		
		// Add a new row
		append(&expr.rows, [2]^Expr {})
		last_row := &expr.rows[len(expr.rows) - 1]
		
		last_row[0] = parse_expr_list(text, pos)
		token := parse_math_token(text, pos^)
		assert(token.kind == .Ampersand)
		pos^ = token.end

		last_row[1] = parse_expr_list(text, pos)
		token = parse_math_token(text, pos^)
		pos^ = token.end
		if token.kind == .End_Aligned {
			break
		}
		assert(token.kind == .Double_Backslash)
	}

	return expr
}