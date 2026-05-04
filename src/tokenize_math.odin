#+private file
package main

import "core:fmt"

@(private)
Math_Token :: struct {
	start, end: int,
	kind: Math_Token_Kind,
}

@(private)
Math_Token_Kind :: enum {
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
	Begin_Aligned,
	End_Aligned,
	Open_Curly_Brace,
	Close_Curly_Brace,
	Open_Bracket,
	Close_Bracket,
	Ampersand,
	Double_Backslash,
}

@(private)
parse_math_token :: proc(text: string, pos: int) -> Math_Token {
	pos := pos
	
	// Skip preceding whitespace
	for {
		c, c_size := get_char(text, pos)
		
		if c == 0 {
			return Math_Token { pos, 0, .File_End }
		}

		if c != ' ' && c != '\t' && c != '\n' do break
		pos += c_size
	}

	c := text[pos]

	token := Math_Token {
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
	
	case '&':
		pos += 1
		token.kind = .Ampersand

	case:
		fmt.panicf("Unsupportd character '%r' at position %v", c, pos)
	}

	token.end = pos

	return token
}

parse_letter :: proc(content: string, index: ^int) -> Math_Token_Kind {
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

parse_backslash :: proc(text: string, pos: ^int) -> Math_Token_Kind {
	if text[pos^] == '\\' {
		pos^ += 1
		return .Double_Backslash
	}

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
	case "left":
		c := text[pos^]
		if c == '[' || c == '(' {
			pos^ += 1
		}
		
	case "right":
		c := text[pos^]
		if c == ']' || c == ')' {
			pos^ += 1
		}
	case "begin":
		// #todo: Copy paste, turn into function
		c := text[pos^]
		assert(c == '{')
		pos^ += 1
		environment_start := pos^

		for {
			c = text[pos^]
			assert((c >= 'a' && c <= 'z') || c == '}')
			pos^ += 1
			if c == '}' do break
		}

		environment := text[environment_start : pos^ - 1]
		if environment == "aligned" {
			return .Begin_Aligned
		}

		fmt.panicf("begin environment %v not supported", environment)
	
	case "end":
		c := text[pos^]
		assert(c == '{')
		pos^ += 1
		environment_start := pos^

		for {
			c = text[pos^]
			assert((c >= 'a' && c <= 'z') || c == '}')
			pos^ += 1
			if c == '}' do break
		}

		environment := text[environment_start : pos^ - 1]
		if environment == "aligned" {
			return .End_Aligned
		}

		fmt.panicf("end environment %v not supported", environment)
	}

	return .Operator
}