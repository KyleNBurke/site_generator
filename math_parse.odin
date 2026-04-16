package main

import "core:fmt"

parse_math_expr :: proc(content: string, index: ^int) -> []^Expr {
    return parse_expr(content, index)
}

parse_expr :: proc(content: string, index: ^int) -> []^Expr {
	exprs: [dynamic]^Expr
	
	loop: for {
		token := parse_token(content, index^)
		if token.kind == .Math_End do break
		
		expr := parse_terminal_expr(content, index)

		token = parse_token(content, index^)
		
		#partial switch token.kind {
		case .Math_End:
			append(&exprs, expr)
			break loop

		case .Carrot:
			index^ = token.end

			superscript_expr := make_expr(Superscript_Expr)
			superscript_expr.base_expr = expr
			superscript_expr.super_expr = parse_terminal_expr(content, index)

			expr = superscript_expr
		}

		append(&exprs, expr)
	}

	return exprs[:]
}

/*
parse_expr_old :: proc(content: string, index: ^int, min_bp: int) -> ^Expr {
	left_expr := parse_terminal_expr(content, index)

	loop: for {
		token := parse_token(content, index^)
		l_bp, r_bp: int
		op: u8

		#partial switch token.kind {
		case .Math_End:
			break loop
			
		case .Plus, .Equals:
			index^ = token.end
			l_bp, r_bp = 1, 2
			op = content[token.start]
		
		case .Carrot:
			index^ = token.end
			l_bp, r_bp = 3, 4
			op = content[token.start]
		
		case:
			l_bp, r_bp = 1, 2
			// break loop
		}

		if l_bp < min_bp {
			break
		}
		
		right_expr := parse_expr(content, index, r_bp)

		op_expr := make_expr(Binary_Operator_Expr)
		op_expr.op = op
		op_expr.left_expr = left_expr
		op_expr.right_expr = right_expr

		left_expr = op_expr
	}

	return left_expr
}
*/

parse_terminal_expr :: proc(content: string, index: ^int) -> ^Expr {
    token := parse_token(content, index^)

	#partial switch token.kind {
	case .Identifier:
		index^ = token.end
		expr := make_expr(Ident_Expr)
		expr.str = content[token.start : token.end]
		return expr
	
	case .String:
		index^ = token.end
		expr := make_expr(String_Expr)
		expr.str = content[token.start : token.end]
		return expr
	
	case .Number:
		index^ = token.end
		expr := make_expr(Number_Expr)
		expr.str = content[token.start : token.end]
		return expr
	
	case .Operator:
		index^ = token.end
		expr := make_expr(Operator_Expr)
		expr.op = content[token.start]
		return expr
	
	// case .Open_Curly_Brace:
	// 	index^ = token.end
		
	// 	row_expr := make_expr(Row_Expr)
	// 	row_expr.row_expr = parse_expr(content, index)
		
	// 	token = parse_token(content, index^)
	// 	assert(token.kind == .Close_Curly_Brace)
	// 	index^ = token.end
		
	// 	expr = row_expr
	}

	unreachable()
}