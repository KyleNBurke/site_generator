package main

import "core:os"
import "core:fmt"
import "core:strings"

METADATA_SEPARATOR :: "#---"

Article :: struct {
    file_name: string,
    title: string,
}

get_char :: proc(text: string, pos: int) -> (u8, int) {
	assert(pos <= len(text))
	
	if pos == len(text) {
		return 0, 0
	}
	
	c := text[pos]

	// Convert '\r\n' to '\n'
	if c == '\r' && pos < len(text) {
		if text[pos + 1] == '\n' {
			return '\n', 2
		}
	}

	return c, 1
}

main :: proc() {
    fmt.assertf(len(os.args) > 1, "Error: Pages directory not provided.")
    pages_dir := os.args[1]

    file_infos, error := os.read_directory_by_path(pages_dir, 0, context.allocator)
    assert(error == nil)

    site_dir_error := os.make_directory("site")
    assert(site_dir_error == nil || site_dir_error == .Exist)

    // Articles
    article_dir_error := os.make_directory("site/article")
    assert(article_dir_error == nil || article_dir_error == .Exist)

    articles: [dynamic]Article

    for file_info in file_infos {
        if file_info.type != .Regular do continue

        extension := file_info.name[len(file_info.name) - 3:]
        if extension != ".md" do continue

        file_text, read_error := os.read_entire_file(file_info.fullpath, context.allocator)
        fmt.assertf(read_error == nil, "Failed to read page file %v\nError: %v", file_info.fullpath, read_error)
		file_string := transmute(string) file_text

		sep_index := strings.index(file_string, METADATA_SEPARATOR)
		fmt.assertf(sep_index != -1, "No metadata separator found.")

		// Metadata
		article: Article
		metadata := file_string[:sep_index]

		for {
            line, ok := strings.split_lines_iterator(&metadata)
            if !ok do break
            if line == "" do continue
            
            result, split_error := strings.split(line, "=")
            assert(split_error == .None)

            key := strings.trim_space(result[0])
            value := strings.trim_space(result[1])
            
            switch key {
            case "title":
                article.title = value
			
			case:
				fmt.panicf("Invalid key %v", key)
            }
        }

        // Content
        // #TODO: Use io.Writer somehow. I think we can directly write to the file ssytem.
        builder := strings.builder_make()

        strings.write_string(&builder, "<h1 class=\"title\">")
        strings.write_string(&builder, article.title)
        strings.write_string(&builder, "</h1>\n")

        pos := sep_index + len(METADATA_SEPARATOR)

        loop: for {
			c, c_size := get_char(file_string, pos)

            switch c {
			case 0:
				break loop
			
			case '\n':
				pos += c_size
				continue

            case '#':
				pos += 1
                level := 1

				for {
					c, c_size = get_char(file_string, pos)
					if c != '#' do break
					pos += 1
					level += 1
				}

                heading_open := fmt.tprintf("<h%v>", level)
                strings.write_string(&builder, heading_open)

                start := pos

                for {
					c, c_size = get_char(file_string, pos)
					if c == 0 do break
					pos += 1
					if c == '\n' do break
                }

                heading := strings.trim_space(file_string[start : pos])
                strings.write_string(&builder, heading)

                heading_close := fmt.tprintf("</h%v>", level)
                strings.write_string(&builder, heading_close)

                strings.write_rune(&builder, '\n')

			case '-':
				// #todo: Unordered list items actually need a following space: "- "
				// #todo: Trim trailing and leading space: <li> hello </li>
				strings.write_string(&builder, "<ul>")

				for {
					c, c_size = get_char(file_string, pos)
					if c != '-' do break
					pos += 1

					strings.write_string(&builder, "<li>") // #todo

					for {
						c, c_size = get_char(file_string, pos)
						pos += c_size
						if c == 0 || c == '\n' do break
						
						// #todo: Need a generic handle character proc so I can handle code characters in here
						if c == '$' {
							handle_math_char(&builder, file_string, &pos)
						} else {
							strings.write_byte(&builder, c)
						}
					}

					strings.write_string(&builder, "</li>")
				}

				strings.write_string(&builder, "</ul>")
			
			case '`':
				pos += 1
				handle_code_char(&builder, file_string, &pos)
			
			case '$':
				pos += 1
				handle_math_char(&builder, file_string, &pos)

            case:
                build_paragraph(&builder, file_string, &pos, c)
            }
        }

        article_html := strings.to_string(builder)

        file_stem := file_info.name[:len(file_info.name) - 3]
        file_name := fmt.tprintf("%s.html", file_stem)
        file_path := fmt.tprintf("site/article/%s", file_name)

        HOME_BUTTON :: "<a href=\"../index.html\">Home</a>"

        article_page_html, _ := strings.replace(HTML, "#style_path#", "../style.css", 1)
        article_page_html, _ = strings.replace(article_page_html, "#home_button#", HOME_BUTTON, 1)
        article_page_html, _ = strings.replace(article_page_html, "#content#", article_html, 1)
        
        write_error := os.write_entire_file(file_path, article_page_html)
        fmt.assertf(write_error == nil, "Error: %v", write_error)

        article.file_name = file_name
        append(&articles, article)
    }

    // Home page
    articles_builder := strings.builder_make()

    strings.write_string(&articles_builder, "<ul>")

    for article in articles {
        line := fmt.aprintfln("<li><a href=\"article/%s\">%s</a></li>", article.file_name, article.title)
        strings.write_string(&articles_builder, line)
    }

    strings.write_string(&articles_builder, "</ul>")

    article_links := strings.to_string(articles_builder)
    home_page_text, _ := strings.replace(HTML, "#style_path#", "style.css", 1)
    home_page_text, _ = strings.replace(home_page_text, "#home_button#", "", 1)
    home_page_text, _ = strings.replace(home_page_text, "#content#", article_links, 1)

    error = os.write_entire_file("site/index.html", home_page_text)
    assert(error == nil)

    os.copy_file("site/style.css", "style.css")
}

maybe_parse_link :: proc(builder: ^strings.Builder, text: string, pos: ^int) -> bool {
	temp_pos := pos^
	text_start := temp_pos
	
	// Look for ']'
	for {
		c, _ := get_char(text, temp_pos)
		temp_pos += 1
		if c == '\n' do return false
		if c == ']' do break
	}

	text_end := temp_pos - 1

	c, _ := get_char(text, temp_pos)
	if c != '(' do return false
	temp_pos += 1

	link_start := temp_pos

	// Look for ')'
	for {
		c, _ := get_char(text, temp_pos)
		temp_pos += 1
		if c == '\n' do return false
		if c == ')' do break
	}

	link_end := temp_pos - 1
	pos^ = temp_pos

	link_text := text[text_start : text_end]
	link      := text[link_start : link_end]

	html_start := fmt.tprintf("<a href=\"%s\">", link)
	strings.write_string(builder, html_start)
	strings.write_string(builder, link_text)
	strings.write_string(builder, "</a>")

	return true
}

handle_code_char :: proc(builder: ^strings.Builder, text: string, pos: ^int) {
	if pos^ + 2 <= len(text) && text[pos^ : pos^ + 2] == "``" {
		pos^ += 2
		strings.write_string(builder, "\n<pre>\n<code>")

		// #todo: parse the language

		loop_1: for {
			c, c_size := get_char(text, pos^)
			pos^ += c_size

			switch c {
			case 0:
				panic("Didn't close out the code block")

			case '`':
				if pos^ + 2 <= len(text) && text[pos^ : pos^ + 2] == "``" {
					pos^ += 2
					break loop_1
				}
			}

			strings.write_byte(builder, c)
		}

		strings.write_string(builder, "\n</code>\n</pre>\n")
	} else {
		strings.write_string(builder, "<code style=\"background-color: lightgrey;\">")

		loop_2: for {
			c, c_size := get_char(text, pos^)
			pos^ += c_size
			
			switch c {
			case 0:
				panic("Didn't close out the inline code")
			
			case '`':
				break loop_2
			}
			
			strings.write_byte(builder, c)
		}

		strings.write_string(builder, "</code>")
	}
}

handle_math_char :: proc(builder: ^strings.Builder, text: string, pos: ^int) {
	single_dollar := true
			
	next_c, _ := get_char(text, pos^)
	if next_c == '$' {
		pos^ += 1
		single_dollar = false
	}
	
	expr := parse_math_expr(text, pos, single_dollar)
    
	if single_dollar {
    	strings.write_string(builder, "<math>\n")
	} else {
		strings.write_string(builder, "<math display=\"block\">\n")
	}

	build_expr(builder, expr)

    strings.write_string(builder, "</math>")
}

build_paragraph :: proc(builder: ^strings.Builder, text: string, pos: ^int, c: u8) {
    strings.write_string(builder, "<p>")

    loop: for {
		c, c_size := get_char(text, pos^)
		pos^ += c_size

        switch c {
        case 0:
			break loop
		
		case '\n':
            break loop
		
		case '[':
			parsed_link := maybe_parse_link(builder, text, pos)
			
			if !parsed_link {
				strings.write_byte(builder, c)
			}
		
		case '`':
			handle_code_char(builder, text, pos)
        
        case '$':
			handle_math_char(builder, text, pos)

        case:
            strings.write_byte(builder, c)
        }
    }

    strings.write_string(builder, "</p>")
    strings.write_rune(builder, '\n')
}

build_expr :: proc(builder: ^strings.Builder, expr: ^Expr) {
    switch expr_var in expr.variant {
	case ^Expr_List:
		for expr in expr_var.exprs {
			build_expr(builder, expr)
		}

    case ^Ident_Expr:
        strings.write_string(builder, "<mi>")
        strings.write_string(builder, expr_var.str)
        strings.write_string(builder, "</mi>")
	
	case ^String_Expr:
        strings.write_string(builder, "<ms>")

		if expr_var.str == ", " {
			strings.write_string(builder, ",&nbsp;")
		} else {
			strings.write_string(builder, expr_var.str)
		}
        
        strings.write_string(builder, "</ms>")
	
	case ^Number_Expr:
		strings.write_string(builder, "<mn>")
        strings.write_string(builder, expr_var.str)
        strings.write_string(builder, "</mn>")

	case ^Superscript_Expr:
        strings.write_string(builder, "<msup>")
        build_expr(builder, expr_var.base_expr)
        build_expr(builder, expr_var.super_expr)
        strings.write_string(builder, "</msup>")
        
	case ^Subscript_Expr:
		strings.write_string(builder, "<msub>")
        build_expr(builder, expr_var.base_expr)
        build_expr(builder, expr_var.sub_expr)
        strings.write_string(builder, "</msub>")
	
	case ^Sub_Sup_Expr:
		strings.write_string(builder, "<msubsup>")
        build_expr(builder, expr_var.base_expr)
        build_expr(builder, expr_var.sub_expr)
		build_expr(builder, expr_var.super_expr)
        strings.write_string(builder, "</msubsup>")
	
	case ^Operator_Expr:
		op: string

		switch expr_var.op {
		case "+", "-", "=", ">", "<", "[", "]":
			op = expr_var.op
		
		case "\\in": op = "&isin;"
		case "\\ne": op = "&ne;"
		case "\\pm": op = "&plusmn;"
		case "\\left[": op = "["
		case "\\right]": op = "]"
		case "\\left(": op = "("
		case "\\right)": op = ")"
		
		case:
			op = expr_var.op[1:]
		
		// case:
		// 	fmt.panicf("Operator not supported \"%s\"", expr_var.op)
		}
		
		strings.write_string(builder, "<mo>")
		strings.write_string(builder, op)
		strings.write_string(builder, "</mo>")
	
	case ^Operator_Frac_Expr:
		strings.write_string(builder, "<mfrac>")
		build_expr(builder, expr_var.top_expr)
		build_expr(builder, expr_var.bottom_expr)
		strings.write_string(builder, "</mfrac>")
	
	case ^Root_Expr:
		if expr_var.degree == "" {
			strings.write_string(builder, "<msqrt>")
			build_expr(builder, expr_var.sqrt_expr)
			strings.write_string(builder, "</msqrt>")
		} else {
			strings.write_string(builder, "<mroot>")
			build_expr(builder, expr_var.sqrt_expr)
			strings.write_string(builder, "<mi>")
			strings.write_string(builder, expr_var.degree)
			strings.write_string(builder, "</mi>")
			strings.write_string(builder, "</mroot>")
		}

	case ^Curly_Braced_Expr:
		strings.write_string(builder, "<mrow>")
		build_expr(builder, expr_var.expr_list)
        strings.write_string(builder, "</mrow>")
	
	case ^Table_Expr:
		strings.write_string(builder, "<mtable>")

		for row_expr in expr_var.rows {
			strings.write_string(builder, "<mtr>")
			strings.write_string(builder, "<mtd>")
			build_expr(builder, row_expr)
			strings.write_string(builder, "</mtd>")
			strings.write_string(builder, "</mtr>")
		}

		strings.write_string(builder, "</mtable>")
	
	case ^Aligned_Table_Expr:
		strings.write_string(builder, "<mtable>\n")

		for row_expr in expr_var.rows {
			strings.write_string(builder, "<mtr>")

			strings.write_string(builder, "<mtd>")
			build_expr(builder, row_expr[0])
			strings.write_string(builder, "</mtd>")

			strings.write_string(builder, "<mtd>")
			build_expr(builder, row_expr[1])
			strings.write_string(builder, "</mtd>")
			
			strings.write_string(builder, "</mtr>\n")
		}

		strings.write_string(builder, "</mtable>\n")
	
	// case ^Aligned_Exprs:
	// 	panic("")
    }
}

HTML ::
`<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="#style_path#">
</head>
<body>
    <header>
        <h1>Kyle Burke</h1>
        #home_button#
    </header>
#content#
</body>
</html>`