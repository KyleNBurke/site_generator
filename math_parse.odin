package main

import "core:fmt"

parse_math_expr :: proc(text: string, pos: ^int, single_dollar: bool) -> ^Expr {
    expr := parse_expr(text, pos)
	
	token := parse_token(text, pos^)
	if single_dollar {
		assert(token.kind == .Dollar)
	} else {
		assert(token.kind == .Double_Dollar)
	}
	
	pos^ = token.end
	
	return expr
}

parse_expr :: proc(text: string, pos: ^int) -> ^Expr {
	exprs: [dynamic][dynamic]^Expr
	append(&exprs, [dynamic]^Expr {})
	
	for {
		token := parse_token(text, pos^)
		if token.kind == .Double_Backslash {
			pos^ = token.end
			// Create a new row
			append(&exprs, [dynamic]^Expr {})
		}

		expr := parse_expr_2(text, pos)
		if expr == nil do break

		last_row := &exprs[len(exprs) - 1]
		append(last_row, expr)
	}

	// If there is only one row, we did not parse a table
	if len(exprs) == 1 {
		// If the row only contains one expression, just return that single expression back
		if len(exprs[0]) == 1 {
			return exprs[0][0]
		}

		expr_list := make_expr(Expr_List)
		expr_list.exprs = exprs[0][:]
		return expr_list
	}

	rows: [dynamic]^Expr
	
	for row in exprs {
		assert(len(row) > 0)
		
		if len(row) == 0 {
			append(&rows, row[0])
		} else {
			expr_list := make_expr(Expr_List)
			expr_list.exprs = row[:]
			append(&rows, expr_list)
		}
	}

	table_expr := make_expr(Table_Expr)
	table_expr.rows = rows[:]

	return table_expr
}

/*
parse_aligned_exprs :: proc(text: string, pos: ^int, aligned_exprs: ^Aligned_Exprs) {
	rows: [dynamic]Aligned_Exprs_Row

	for {
		left_exprs: [dynamic]^Expr

		for {
			token := parse_token(text, pos^)
			if token.kind == .Ampersand {
				pos^ = token.end
				break
			}
			
			expr := parse_expr(text, pos)
			assert(expr != nil)
			append(&left_exprs, expr)
		}

		right_exprs: [dynamic]^Expr

		for {
			token := parse_token(text, pos^)
			if token.kind == .Double_Backslash {
				pos^ = token.end
				break
			}
			
			expr := parse_expr(text, pos)
			assert(expr != nil)
			append(&right_exprs, expr)
		}

		aligned_row := Aligned_Exprs_Row {
			left_exprs = left_exprs[:],
			right_exprs = right_exprs[:],
		}

		append(&rows, aligned_row)
	}

	aligned_exprs.rows = rows[:]
}
*/

parse_expr_2 :: proc(text: string, pos: ^int) -> ^Expr {
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
		unimplemented()
		// pos^ = token.end

		// row_expr := make_expr(Row_Expr)
		// row_expr.exprs = parse_exprs(text, pos)

		// token = parse_token(text, pos^)
		// assert(token.kind == .Close_Curly_Brace)
		// pos^ = token.end

		// expr = row_expr
	
	case .Open_Bracket, .Close_Bracket:
		pos^ = token.end
		ident_expr := make_expr(Ident_Expr)
		ident_expr.str = text[token.start : token.end]
		expr = ident_expr
	
	case .Begin_Align:
		pos^ = token.end

	}

	return expr
}

parse_frac_expr :: proc(text: string, pos: ^int, expr: ^Operator_Frac_Expr) {
	// #todo: Can this be part of a generic curly brace parsing?
	token := parse_token(text, pos^)
	assert(token.kind == .Open_Curly_Brace)
	pos^ = token.end

	expr.top_expr = parse_expr(text, pos)
	
	token = parse_token(text, pos^)
	assert(token.kind == .Close_Curly_Brace)
	pos^ = token.end

	token = parse_token(text, pos^)
	assert(token.kind == .Open_Curly_Brace)
	pos^ = token.end

	expr.bottom_expr = parse_expr(text, pos)
	
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

	expr.sqrt_expr = parse_expr(text, pos)

	token = parse_token(text, pos^)
	assert(token.kind == .Close_Curly_Brace)
	pos^ = token.end
}