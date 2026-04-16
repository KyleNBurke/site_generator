package main

import "core:fmt"

parse_math_expr :: proc(content: string, index: ^int, single_dollar: bool) -> []^Expr {
    exprs := parse_exprs(content, index)
	
	token := parse_token(content, index^)
	if single_dollar {
		assert(token.kind == .Dollar)
	} else {
		assert(token.kind == .Double_Dollar)
	}
	
	index^ = token.end
	
	return exprs
}

parse_exprs :: proc(content: string, index: ^int) -> []^Expr {
	exprs: [dynamic]^Expr
	
	loop: for {
		expr := parse_terminal_expr(content, index)
		if expr == nil do break

		token := parse_token(content, index^)
		
		#partial switch token.kind {
		case .Dollar, .Double_Dollar:
			append(&exprs, expr)
			break loop

		case .Carrot:
			index^ = token.end

			superscript_expr := make_expr(Superscript_Expr)
			superscript_expr.base_expr = expr
			superscript_expr.super_expr = parse_terminal_expr(content, index)

			expr = superscript_expr
		
		case .Underscore:
			index^ = token.end

			subscript_expr := make_expr(Subscript_Expr)
			subscript_expr.base_expr = expr
			subscript_expr.sub_expr = parse_terminal_expr(content, index)

			expr = subscript_expr
		}

		append(&exprs, expr)
	}

	return exprs[:]
}

parse_terminal_expr :: proc(content: string, index: ^int) -> ^Expr {
	expr: ^Expr
    token := parse_token(content, index^)

	#partial switch token.kind {
	case .Identifier:
		index^ = token.end
		ident_expr := make_expr(Ident_Expr)
		ident_expr.str = content[token.start : token.end]
		expr = ident_expr
	
	case .String:
		index^ = token.end
		string_expr := make_expr(String_Expr)
		string_expr.str = content[token.start : token.end]
		expr = string_expr
	
	case .Number:
		index^ = token.end
		number_expr := make_expr(Number_Expr)
		number_expr.str = content[token.start : token.end]
		expr = number_expr
	
	case .Operator:
		index^ = token.end
		op_expr := make_expr(Operator_Expr)
		op_expr.op = content[token.start]
		expr = op_expr
	
	case .Open_Curly_Brace:
		index^ = token.end

		row_expr := make_expr(Row_Expr)
		row_expr.exprs = parse_exprs(content, index)

		token = parse_token(content, index^)
		assert(token.kind == .Close_Curly_Brace)
		index^ = token.end

		expr = row_expr
	}

	return expr
}