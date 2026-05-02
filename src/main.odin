package main

import "core:os"
import "core:fmt"
import "core:strings"
import "core:time"

METADATA_SEPARATOR :: "#---"

Article :: struct {
    rel_html_file_path: string,
    title: string,
	html: string,
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

	if os.exists("site") {
		backup_path := fmt.tprintf("site_backup_%v", time.time_to_unix(time.now()))
		fmt.printfln("Backing up site directory to %s", backup_path)
		rename_error := os.rename("site", backup_path)
		assert(rename_error == nil)

		remove_error := os.remove_all("site")
		assert(remove_error == nil)
	}

	make_dir_error := os.make_directory("site")
	assert(make_dir_error == nil)

    // Articles
    article_dir_error := os.make_directory("site/article")
    assert(article_dir_error == nil || article_dir_error == .Exist)

    articles: [dynamic]Article

    for file_info in file_infos {
		md_file_path: string

		#partial switch file_info.type {
		case .Directory:
			// Open the directory
			nested_file_infos, error := os.read_directory_by_path(file_info.fullpath, 0, context.allocator)
			assert(error == nil)

			// Look for an .md file
			for nested_file_info in nested_file_infos {
				extension := nested_file_info.name[len(nested_file_info.name) - 3:]
				if extension == ".md" {
					md_file_path = nested_file_info.fullpath
					break
				}
			}

			fmt.assertf(md_file_path != "", "Missing markdown file in directory %s", file_info.fullpath)

			// Convert back slashes to forward slashes
			md_file_path, _ = strings.replace_all(md_file_path, "\\", "/")

		case .Regular:
			extension := file_info.name[len(file_info.name) - 3:]
			fmt.assertf(extension == ".md", "File %s must be a markdown file", file_info.fullpath)

			// Convert back slashes to forward slashes
			md_file_path, _ = strings.replace_all(file_info.fullpath, "\\", "/")

		case:
			fmt.panicf("File %s is an unsupported type: %s", file_info.fullpath, file_info.type)
		}

		article: Article

		rel_md_file_path_no_ext := md_file_path[len(pages_dir) + 1 : len(md_file_path) - 3]
		article.rel_html_file_path = fmt.tprintf("article/%s.html", rel_md_file_path_no_ext)
		
		html_file_path := fmt.tprintf("site/article/%s.html", rel_md_file_path_no_ext)
		fmt.printfln("Generating article %s from %s", html_file_path, md_file_path)
		
        build_article(md_file_path, &article)

		depth := strings.count(md_file_path, "/") - 1
		home_page_file_path: string
		style_file_path: string

		if depth == 0 {
			home_page_file_path = "../index.html"
        	style_file_path = "../style.css"
		} else {
			home_page_file_path = "../../index.html"
			style_file_path = "../../style.css"

			assert(file_info.type == .Directory)

			// Create the output directory
			article_dir := fmt.tprintf("site/article/%s", file_info.name)
			error = os.make_directory(article_dir)
			assert(error == nil)

			// Open the input directory
			nested_file_infos, error := os.read_directory_by_path(file_info.fullpath, 0, context.allocator)
			assert(error == nil)

			// Copy the files
			for nested_file_info in nested_file_infos {
				extension := nested_file_info.name[len(nested_file_info.name) - 3:]
				if extension == ".md" do continue

				fmt.assertf(nested_file_info.type == .Regular, "Cannot copy file %s", nested_file_info.fullpath)

				dst := fmt.tprintf("%s/%s", article_dir, nested_file_info.name)
				error := os.copy_file(dst, nested_file_info.fullpath)
				fmt.assertf(error == nil, "Failed to copy %s to %s, error: %v", nested_file_info.fullpath, dst, error)
				fmt.printfln("\tCopied %s", nested_file_info.fullpath)
			}
		}

		home_button := fmt.tprintf("<a href=\"%s\">Home</a>", home_page_file_path)

		page_html, _ := strings.replace(HTML, "#style_path#", style_file_path, 1)
		page_html, _ = strings.replace(page_html, "#home_button#", home_button, 1)
		page_html, _ = strings.replace(page_html, "#content#", article.html, 1)

		write_error := os.write_entire_file(html_file_path, page_html)
		fmt.assertf(write_error == nil, "Failed to write article %s, error: %v", html_file_path, write_error)

		append(&articles, article)
    }

    // Home page
    articles_builder := strings.builder_make()

    strings.write_string(&articles_builder, "<ul>")

    for article in articles {
        line := fmt.aprintfln("<li><a href=\"%s\">%s</a></li>", article.rel_html_file_path, article.title)
        strings.write_string(&articles_builder, line)
    }

    strings.write_string(&articles_builder, "</ul>")

    article_links := strings.to_string(articles_builder)
    home_page_text, _ := strings.replace(HTML, "#style_path#", "style.css", 1)
    home_page_text, _ = strings.replace(home_page_text, "#home_button#", "", 1)
    home_page_text, _ = strings.replace(home_page_text, "#content#", article_links, 1)

    error = os.write_entire_file("site/index.html", home_page_text)
    assert(error == nil)

	style_css := #load("../res/style.css")
	write_error := os.write_entire_file("site/style.css", style_css)
	assert(write_error == nil)
}

build_article :: proc(file_path: string, article: ^Article) {
	file_text, read_error := os.read_entire_file(file_path, context.allocator)
	fmt.assertf(read_error == nil, "Failed to read page file %v\nError: %v", file_path, read_error)
	text := transmute(string) file_text

	sep_index := strings.index(text, METADATA_SEPARATOR)
	fmt.assertf(sep_index != -1, "No metadata separator found.")

	metadata := text[:sep_index]

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
	builder := strings.builder_make()

	strings.write_string(&builder, "<h1 class=\"title\">")
	strings.write_string(&builder, article.title)
	strings.write_string(&builder, "</h1>\n")

	pos := sep_index + len(METADATA_SEPARATOR)

	loop: for {
		c, c_size := get_char(text, pos)
		pos += c_size

		switch c {
		case 0:
			break loop
		
		case '\n':
			continue

		case '#':
			build_heading(&builder, text, &pos)
			continue
		
		case '-':
			if maybe_build_unordered_list(&builder, text, &pos) {
				continue
			}

		case '1':
			if maybe_build_ordered_list(&builder, text, &pos) {
				continue
			}
		
		case '!':
			if maybe_build_image(&builder, text, &pos) {
				continue
			}
		
		case '`':
			build_inline_or_block_code(&builder, text, &pos)
			continue
		
		case '$':
			build_inline_or_block_math(&builder, text, &pos)
			continue
		}

		build_paragraph(&builder, text, &pos, c)
	}

	article.html = strings.to_string(builder)
}

build_paragraph :: proc(builder: ^strings.Builder, text: string, pos: ^int, c: u8) {
	strings.write_string(builder, "<p>")
	strings.write_byte(builder, c)

	loop: for {
		c, c_size := get_char(text, pos^)
		if c == 0 || c == '\n' do break
		pos^ += c_size

		handle_paragraph_char(builder, text, pos, c)
	}

	strings.write_string(builder, "</p>\n")
}

handle_paragraph_char :: proc(builder: ^strings.Builder, text: string, pos: ^int, c: u8) {
	switch c {
	case '[':
		if maybe_build_link(builder, text, pos) {
			return
		}
	
	case '`':
		build_inline_code(builder, text, pos)
		return
	
	case '$':
		build_inline_math(builder, text, pos)
		return
	}

	strings.write_byte(builder, c)
}

build_heading :: proc(builder: ^strings.Builder, text: string, pos: ^int) {
	level := 1

	for {
		c, _ := get_char(text, pos^)
		if c != '#' do break
		pos^ += 1
		level += 1
	}

	open_tag := fmt.tprintf("<h%v>", level)
	strings.write_string(builder, open_tag)

	start := pos^

	for {
		c, _ := get_char(text, pos^)
		if c == 0 do break
		pos^ += 1
		if c == '\n' do break
	}

	text := strings.trim_space(text[start : pos^])
	strings.write_string(builder, text)

	close_tag := fmt.tprintf("</h%v>\n", level)
	strings.write_string(builder, close_tag)
}

maybe_build_unordered_list :: proc(builder: ^strings.Builder, text: string, pos: ^int) -> bool {
	c, _ := get_char(text, pos^)
	if c != ' ' do return false
	pos^ += 1
	
	strings.write_string(builder, "<ul>")

	for {
		strings.write_string(builder, "<li>")

		for {
			c, c_size := get_char(text, pos^)
			pos^ += c_size
			if c == 0 || c == '\n' do break
			
			// #todo: The problem with this is we can't trim any trailing/leading whitespace: <li> hello </li>
			handle_paragraph_char(builder, text, pos, c)
		}

		strings.write_string(builder, "</li>")

		c, _ := get_char(text, pos^)
		if c != '-' do break
		pos^ += 1
	}

	strings.write_string(builder, "</ul>")
	return true
}

maybe_build_ordered_list :: proc(builder: ^strings.Builder, text: string, pos: ^int) -> bool {
	c, _ := get_char(text, pos^)
	if c != '.' do return false
	pos^ += 1

	c, _ = get_char(text, pos^)
	if c != ' ' do return false
	pos^ += 1

	strings.write_string(builder, "<ol>")

	for {
		strings.write_string(builder, "<li>")

		for {
			c, c_size := get_char(text, pos^)
			pos^ += c_size
			if c == 0 || c == '\n' do break
			
			// #todo: The problem with this is we can't trim any trailing/leading whitespace: <li> hello </li>
			handle_paragraph_char(builder, text, pos, c)
		}

		strings.write_string(builder, "</li>")

		if pos^ + 3 > len(text) || text[pos^ : pos^ + 3] != "1. " {
			break
		}

		pos^ += 3
	}

	strings.write_string(builder, "</ol>")
	return true
}

maybe_build_image :: proc(builder: ^strings.Builder, text: string, pos: ^int) -> bool {
	temp_pos := pos^

	c, _ := get_char(text, temp_pos)
	if c != '[' do return false
	temp_pos += 1
	
	text_start := temp_pos
	
	// Look for ']'
	for {
		c, _ := get_char(text, temp_pos)
		temp_pos += 1
		if c == '\n' do return false
		if c == ']' do break
	}

	text_end := temp_pos - 1

	c, _ = get_char(text, temp_pos)
	if c != '(' do return false
	temp_pos += 1

	path_start := temp_pos

	// Look for ')'
	for {
		c, _ := get_char(text, temp_pos)
		temp_pos += 1
		if c == '\n' do return false
		if c == ')' do break
	}

	path_end := temp_pos - 1
	pos^ = temp_pos

	alt_text := text[text_start : text_end]
	path     := text[path_start : path_end]
	
	if strings.starts_with(path, "https://www.youtube.com") {
		sep := "/watch?v="
		video_id_index := strings.index(path, sep)
		assert(video_id_index != 0)
		video_id := path[video_id_index + len(sep):]

		link := fmt.tprintf("<a href=\"%s\" target=\"_blank\">", path)
		img  := fmt.tprintf("<img src=\"https://img.youtube.com/vi/%s/0.jpg\" alt=\"%s\">", video_id, alt_text)

		strings.write_string(builder, link)
		strings.write_string(builder, img)
		strings.write_string(builder, "</a>")
	} else {
		html := fmt.tprintf("<img src=\"%s\" alt=\"%s\" />", path, alt_text)
		strings.write_string(builder, html)
	}

	return true
}

maybe_build_link :: proc(builder: ^strings.Builder, text: string, pos: ^int) -> bool {
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

build_inline_or_block_code :: proc(builder: ^strings.Builder, text: string, pos: ^int) {
	if pos^ + 2 > len(text) || text[pos^ : pos^ + 2] != "``" {
		build_inline_math(builder, text, pos)
		return
	}

	pos^ += 2
	
	// Parse over the language, until we hit a new line
	language_start := pos^
	language_end: int
	
	for {
		c, c_size := get_char(text, pos^)
		fmt.assertf(c != 0, "Didn't close out the code block")

		if c == '\n' {
			language_end = pos^
			pos^ += c_size
			break
		}

		pos^ += c_size
	}

	language := text[language_start : language_end]
	
	strings.write_string(builder, "<pre><code>")

	loop: for {
		start_pos := pos^
		end_pos, token_kind := parse_rust_token(text, pos^)
		pos^ = end_pos
		token_str := text[start_pos : end_pos]
		
		switch token_kind {
		case .End:
			break loop
		
		case .Unknown, .Whitespace, .Open_Parenthesis:
			strings.write_string(builder, token_str)
		
		case .Comment:
			strings.write_string(builder, "<span style=\"color: rgb(106, 153, 85);\">")
			strings.write_string(builder, token_str)
			strings.write_string(builder, "</span>")

		case .Keyword:
			strings.write_string(builder, "<span style=\"color: rgb(197, 134, 192);\">")
			strings.write_string(builder, token_str)
			strings.write_string(builder, "</span>")
		
		case .Type:
			strings.write_string(builder, "<span style=\"color: rgb(78, 201, 176);\">")
			strings.write_string(builder, token_str)
			strings.write_string(builder, "</span>")

		case .Identifier:
			_, next_token := parse_rust_token(text, pos^)
			if next_token == .Open_Parenthesis {
				// Function call
				strings.write_string(builder, "<span style=\"color: rgb(220, 220, 170);\">")
				strings.write_string(builder, token_str)
				strings.write_string(builder, "</span>")
			} else {
				strings.write_string(builder, token_str)
			}
		
		case .Number:
			strings.write_string(builder, "<span style=\"color: rgb(181, 206, 168);\">")
			strings.write_string(builder, token_str)
			strings.write_string(builder, "</span>")
		
		case .Left_Angle_Bracket:
			strings.write_string(builder, "&lt;")
		
		case .Right_Angle_Bracket:
			strings.write_string(builder, "&gt;")
		}
	}

	strings.write_string(builder, "</code></pre>\n")
}

build_inline_code :: proc(builder: ^strings.Builder, text: string, pos: ^int) {
	strings.write_string(builder, "<code class=\"inline_code\">")

	loop: for {
		c, c_size := get_char(text, pos^)
		pos^ += c_size
		
		switch c {
		case 0:   panic("Didn't close out the inline code")
		case '`': break loop
		case '<': strings.write_string(builder, "&lt;")
		case '>': strings.write_string(builder, "&gt;")
		case:     strings.write_byte(builder, c)
		}
	}

	strings.write_string(builder, "</code>")
}

build_inline_or_block_math :: proc(builder: ^strings.Builder, text: string, pos: ^int) {
	c, _ := get_char(text, pos^)
	if c != '$' {
		build_inline_math(builder, text, pos)
		return
	}

	pos^ += 1
	expr := parse_math_expr(text, pos, false)
	
	strings.write_string(builder, "<math display=\"block\">\n")
	build_expr(builder, expr)
	strings.write_string(builder, "</math>")
}

build_inline_math :: proc(builder: ^strings.Builder, text: string, pos: ^int) {
	expr := parse_math_expr(text, pos, true)
	
	strings.write_string(builder, "<math>\n")
	build_expr(builder, expr)
	strings.write_string(builder, "</math>")
}

// #todo: Move to math files
// #todo: Rename to build_math_expr
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
        <h1 class="name_heading">Kyle Burke</h1>
		#home_button#
    </header>
#content#
</body>
</html>`