package main

import "core:fmt"

parse_math_expr :: proc(content: string, index: ^int) -> ^Expr {
    return parse_expr(content, index, 0)
}

parse_expr :: proc(content: string, index: ^int, min_bp: int) -> ^Expr {
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
		string_lit_expr := make_expr(String_Expr)
		string_lit_expr.str = content[token.start : token.end]
		expr = string_lit_expr
	
	case .Number:
		index^ = token.end
		number_expr := make_expr(Number_Expr)
		number_expr.str = content[token.start : token.end]
		expr = number_expr
	}

	return expr
}