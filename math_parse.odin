package main

import "core:fmt"

parse_math_expr :: proc(text: string, pos: ^int, single_dollar: bool) -> []^Expr {
    exprs := parse_exprs(text, pos)
	
	token := parse_token(text, pos^)
	if single_dollar {
		assert(token.kind == .Dollar)
	} else {
		assert(token.kind == .Double_Dollar)
	}
	
	pos^ = token.end
	
	return exprs
}

parse_exprs :: proc(text: string, pos: ^int) -> []^Expr {
	exprs: [dynamic]^Expr
	
	for {
		expr := parse_expr(text, pos)
		if expr == nil do break

		append(&exprs, expr)
	}

	return exprs[:]
}

parse_expr :: proc(text: string, pos: ^int) -> ^Expr {
	expr := parse_terminal_expr(text, pos)

	token := parse_token(text, pos^)
		
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

		token = parse_token(text, pos^)
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
    token := parse_token(text, pos^)

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
		frac_expr := make_expr(Operator_Frac_Expr)
		parse_frac_expr(text, pos, frac_expr)
		expr = frac_expr
	
	case .Operator_Sqrt:
		pos^ = token.end
		sqrt_expr := make_expr(Operator_Sqrt_Expr)
		parse_sqrt_expr(text, pos, sqrt_expr)
		expr = sqrt_expr
	
	case .Open_Curly_Brace:
		pos^ = token.end

		row_expr := make_expr(Row_Expr)
		row_expr.exprs = parse_exprs(text, pos)

		token = parse_token(text, pos^)
		assert(token.kind == .Close_Curly_Brace)
		pos^ = token.end

		expr = row_expr
	
	case .Open_Bracket, .Close_Bracket:
		pos^ = token.end
		ident_expr := make_expr(Ident_Expr)
		ident_expr.str = text[token.start : token.end]
		expr = ident_expr
	}

	return expr
}

parse_frac_expr :: proc(text: string, pos: ^int, expr: ^Operator_Frac_Expr) {
	token := parse_token(text, pos^)
	assert(token.kind == .Open_Curly_Brace)
	pos^ = token.end

	expr.top_exprs = parse_exprs(text, pos)
	
	token = parse_token(text, pos^)
	assert(token.kind == .Close_Curly_Brace)
	pos^ = token.end

	token = parse_token(text, pos^)
	assert(token.kind == .Open_Curly_Brace)
	pos^ = token.end

	expr.bottom_exprs = parse_exprs(text, pos)
	
	token = parse_token(text, pos^)
	assert(token.kind == .Close_Curly_Brace)
	pos^ = token.end
}


parse_sqrt_expr :: proc(text: string, pos: ^int, expr: ^Operator_Sqrt_Expr) {
	token := parse_token(text, pos^)
	if token.kind == .Open_Bracket {
		pos^ = token.end

		token = parse_token(text, pos^)
		assert(token.kind == .Number)
		pos^ = token.end

		token = parse_token(text, pos^)
		assert(token.kind == .Close_Bracket)
		pos^ = token.end
	}
	
	token = parse_token(text, pos^)
	assert(token.kind == .Open_Curly_Brace)
	pos^ = token.end

	expr.sqrt_exprs = parse_exprs(text, pos)

	token = parse_token(text, pos^)
	assert(token.kind == .Close_Curly_Brace)
	pos^ = token.end
}