package main

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
	Open_Curly_Brace,
	Close_Curly_Brace,
}

parse_token :: proc(content: string, index: int) -> Token {
	index := index
	
	// Skip preceding whitespace
	for {
		if index == len(content) {
			return Token { index, 0, .File_End }
		}

		c := content[index]
		if c != ' ' do break
		index += 1
	}

	c := content[index]

	token := Token {
		start = index,
	}

	switch c {
	case '$':
		index += 1
		
		if content[index] == '$' {
			index += 1
			token.kind = .Double_Dollar
		} else {
			token.kind = .Dollar
		}
	
	case 'a' ..= 'z', 'A' ..= 'Z', '(', ')':
		index += 1
		token.kind = .Identifier
		// token.kind = parse_letter(content, &index)
	
	case '0' ..= '9':
		index += 1
		parse_number(content, &index)
		token.kind = .Number
	
	case '^':
		index += 1
		token.kind = .Carrot
	
	case '_':
		index += 1
		token.kind = .Underscore
	
	case '+', '-', '=':
		index += 1
		token.kind = .Operator
	
	case '{':
		index += 1
		token.kind = .Open_Curly_Brace
	
	case '}':
		index += 1
		token.kind = .Close_Curly_Brace

	case:
		unimplemented()
	}

	token.end = index

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

parse_number :: proc(content: string, index: ^int) {
	for {
		c := content[index^]
		if c < '0' || c > '9' do break
		index^ += 1
	}
}