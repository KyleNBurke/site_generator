package main

Rust_Token :: struct {
	start, end: int,
	kind: Rust_Token_Kind,
}

Rust_Token_Kind :: enum {
	End,
	Unknown,
	Whitespace,
	Comment,
	Keyword,
	Type,
	Identifier,
	Number,
	Const_Value,
	Open_Parenthesis,
	Left_Angle_Bracket,
	Right_Angle_Bracket,
}

parse_rust_token :: proc(text: string, pos: int) -> (int, Rust_Token_Kind) {
	pos := pos
	c, c_size := get_char(text, pos)

	token_kind: Rust_Token_Kind

	switch c {
	case ' ', '\t', '\r', '\n':
		pos += c_size
		parse_whitespace(text, &pos)
		token_kind = .Whitespace
		
	case '`':
		token_kind = parse_rust_backtick(text, &pos)
	
	case '/':
		token_kind = parse_rust_forward_slash(text, &pos)
	
	case 'a' ..= 'z', 'A' ..= 'Z', '_':
		token_kind = parse_rust_letter(text, &pos)
	
	case '0' ..= '9':
		parse_rust_number(text, &pos)
		token_kind = .Number
	
	case '(':
		pos += 1
		token_kind = .Open_Parenthesis
	
	case '<':
		pos += 1
		token_kind = .Left_Angle_Bracket
	
	case '>':
		pos += 1
		token_kind = .Right_Angle_Bracket
	
	case:
		pos += 1
		token_kind = .Unknown
	}

	return pos, token_kind
}

parse_whitespace :: proc(text: string, pos: ^int) {
	for {
		c, c_size := get_char(text, pos^)

		switch c {
		case ' ', '\t', '\n':
			pos^ += c_size
			continue
		}

		break
	}
}

parse_rust_backtick :: proc(text: string, pos: ^int) -> Rust_Token_Kind {
	pos^ += 1
	
	c1, _ := get_char(text, pos^)
	c2, _ := get_char(text, pos^ + 1)
	if c1 == '`' && c2 == '`' {
		pos^ += 2
		return .End
	}

	return .Unknown
}

parse_rust_forward_slash :: proc(text: string, pos: ^int) -> Rust_Token_Kind {
	pos^ += 1
	c, _ := get_char(text, pos^)

	if c == '/' {
		for {
			c, _ := get_char(text, pos^)

			if c == '\n' {
				break
			}

			pos^ += 1
		}

		return .Comment
	}

	return .Unknown
}

parse_rust_letter :: proc(text: string, pos: ^int) -> Rust_Token_Kind {
	start := pos^
	pos^ += 1
	
	for {
		c, _ := get_char(text, pos^)

		switch c {
		case 'a' ..= 'z', 'A' ..= 'Z', '0' ..= '9', '_':
			pos^ += 1
			continue
		}

		break
	}

	word := text[start : pos^]
	switch word {
	case "fn", "let", "for", "if", "else", "mut", "in", "as":
		return .Keyword
	
	case "f64", "usize", "u8", "u16", "u32", "i8", "i16", "i32", "str", "Vec", "Option", "Some":
		return .Type
	
	case "None":
		return .Const_Value
	}

	return .Identifier
}

parse_rust_number :: proc(text: string, pos: ^int) {
	pos^ += 1

	for {
		c, _ := get_char(text, pos^)

		switch c {
		case '0' ..= '9':
			pos^ += 1
			continue
		
		case '.':
			next_c, _ := get_char(text, pos^ + 1)
			if next_c >= '0' && next_c <= '9' {
				pos^ += 1
				continue
			}
		}

		break
	}
}