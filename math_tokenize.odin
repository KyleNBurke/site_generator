package main

import "core:fmt"

Token :: struct {
	start, end: int,
	kind: Token_Kind,
}

Token_Kind :: enum {
	File_End,
	Dollar,
	Double_Dollar,
	Identifier,
	String,
	Number,
	Carrot,
	Underscore,
	Operator,
	Operator_Frac,
	Operator_Sqrt,
	Open_Curly_Brace,
	Close_Curly_Brace,
	Open_Bracket,
	Close_Bracket,
}

parse_token :: proc(text: string, pos: int) -> Token {
	pos := pos
	
	// Skip preceding whitespace
	for {
		// #todo: Use get_char()?
		if pos == len(text) {
			return Token { pos, 0, .File_End }
		}

		c := text[pos]
		if c != ' ' do break
		pos += 1
	}

	c := text[pos]

	token := Token {
		start = pos,
	}

	switch c {
	case '$':
		pos += 1
		
		if pos < len(text) && text[pos] == '$' {
			pos += 1
			token.kind = .Double_Dollar
		} else {
			token.kind = .Dollar
		}
	
	// #todo: Need to figure out the brackets
	case 'a' ..= 'z', 'A' ..= 'Z', '(', ')', '|', '\'': // #todo: single qoute doesn't look as good
		pos += 1
		token.kind = .Identifier
		// token.kind = parse_letter(content, &index)
	
	case '0' ..= '9', '.':
		pos += 1
		parse_number(text, &pos)
		token.kind = .Number
	
	case '^':
		pos += 1
		token.kind = .Carrot
	
	case '_':
		pos += 1
		token.kind = .Underscore
	
	case '+', '-', '=', '<', '>':
		pos += 1
		token.kind = .Operator
	
	case ',':
		pos += 1
		token.kind = .String

		if text[pos] == ' ' {
			pos += 1
		}
	
	case '{':
		pos += 1
		token.kind = .Open_Curly_Brace
	
	case '}':
		pos += 1
		token.kind = .Close_Curly_Brace
	
	case '[':
		pos += 1
		token.kind = .Open_Bracket
	
	case ']':
		pos += 1
		token.kind = .Close_Bracket
	
	case '\\':
		pos += 1
		token.kind = parse_backslash(text, &pos)

	case:
		fmt.panicf("Unsupportd character '%r' at position %v", c, pos)
	}

	token.end = pos

	return token
}

parse_letter :: proc(content: string, index: ^int) -> Token_Kind {
	start := index^
	
	for {
		c := content[index^]
		if c < 'a' || c > 'z' do break
		index^ += 1
	}

	if index^ - start == 0 {
		return .Identifier
	}

	return .String
}

parse_number :: proc(text: string, pos: ^int) {
	for {
		c := text[pos^]
		// #todo: We should really only allow one period
		if (c < '0' || c > '9') && c != '.' do break
		pos^ += 1
	}
}

parse_backslash :: proc(text: string, pos: ^int) -> Token_Kind {
	start := pos^
	
	for {
		c := text[pos^]
		if c < 'a' || c > 'z' do break
		pos^ += 1
	}

	str := text[start : pos^]
	switch str {
	case "frac": return .Operator_Frac
	case "sqrt": return .Operator_Sqrt
	}

	return .Operator
}