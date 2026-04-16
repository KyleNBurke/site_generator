package main

import "core:os"
import "core:fmt"
import "core:strings"

Article :: struct {
    file_name: string,
    title: string,
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

        file_data, read_error := os.read_entire_file(file_info.fullpath, context.allocator)
        fmt.assertf(read_error == nil, "Failed to read page file %v\nError: %v", file_info.fullpath, read_error)
        file_text := transmute(string) file_data

        result, split_error := strings.split(file_text, "#---")
		assert(len(result) == 2)
        assert(split_error == .None)

        metadata := result[0]
        content := result[1]

        article: Article
        
        // Metadata
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
            }
        }

        // Content
        // #TODO: Use io.Writer somehow. I think we can directly write to the file ssytem.
        article_builder := strings.builder_make()

        strings.write_string(&article_builder, "<h1 class=\"title\">")
        strings.write_string(&article_builder, article.title)
        strings.write_string(&article_builder, "</h1>\n")

        index := 0

        for index < len(content) {
            r := content[index]

            switch r {
            case '\n':
                index += 1

            case '#':
                index += 1
                level := 1
                
                for index < len(content) {
                    r = content[index]
                    if r != '#' do break
                    index += 1
                    level += 1
                }

                heading_open := fmt.tprintf("<h%v>", level)
                strings.write_string(&article_builder, heading_open)

                start := index

                for index < len(content) {
                    r := content[index]
                    index += 1
                    if r == '\n' do break
                }

                heading := strings.trim_space(content[start : index])
                strings.write_string(&article_builder, heading)

                heading_close := fmt.tprintf("</h%v>", level)
                strings.write_string(&article_builder, heading_close)

                strings.write_rune(&article_builder, '\n')

            case:
                build_paragraph(&article_builder, content, &index)
            }
        }

        /*
        for {
            line, ok := strings.split_lines_iterator(&content)
            if !ok do break
            if line == "" do continue

            if strings.starts_with(line, "##") {
                line = strings.trim_space(line[2:])
                strings.write_string(&article_builder, "<h2>")
                strings.write_string(&article_builder, line)
                strings.write_string(&article_builder, "</h2>")
            } else if strings.starts_with(line, "#") {
                line = strings.trim_space(line[1:])
                strings.write_string(&article_builder, "<h1>")
                strings.write_string(&article_builder, line)
                strings.write_string(&article_builder, "</h1>")
            } else if strings.starts_with(line, "```") {
                strings.write_string(&article_builder, "<pre><code>")

                for {
                    line, ok := strings.split_lines_iterator(&content)
                    fmt.assertf(ok, "Code block was not closed")
                    if line == "```" do break

                    strings.write_string(&article_builder, line)
                    strings.write_rune(&article_builder, '\n')
                }

                strings.write_string(&article_builder, "</code></pre>")
            } else {
                strings.write_string(&article_builder, "<p>")
                strings.write_string(&article_builder, line)
                strings.write_string(&article_builder, "</p>")
            }

            strings.write_rune(&article_builder, '\n')
        }
        */

        article_html := strings.to_string(article_builder)

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

build_paragraph :: proc(builder: ^strings.Builder, content: string, index: ^int) {
    strings.write_string(builder, "<p>")

    loop: for index^ < len(content) {
        r := content[index^]

        switch r {
        case '\n':
            break loop
        
        case '$':
            index^ += 1
            build_math(builder, content, index)

        case:
            strings.write_byte(builder, r)
        }

        index^ += 1
    }

    strings.write_string(builder, "</p>")
    strings.write_rune(builder, '\n')

    index^ += 1
}

build_math :: proc(builder: ^strings.Builder, content: string, index: ^int) {
    expr := parse_math_expr(content, index)
    
    strings.write_string(builder, "<math>")
    build_math_html(builder, expr)
    strings.write_string(builder, "</math>")
}

build_math_html :: proc(builder: ^strings.Builder, exprs: []^Expr) {
	for expr in exprs {
    	build_expr(builder, expr)
	}
}

build_expr :: proc(builder: ^strings.Builder, expr: ^Expr) {
    switch expr_var in expr.variant {
    case ^Ident_Expr:
        strings.write_string(builder, "<mi>")
        strings.write_string(builder, expr_var.str)
        strings.write_string(builder, "</mi>")
	
	case ^String_Expr:
        strings.write_string(builder, "<ms>")
        strings.write_string(builder, expr_var.str)
        strings.write_string(builder, "</ms>")
	
	case ^Number_Expr:
		strings.write_string(builder, "<mn>")
        strings.write_string(builder, expr_var.str)
        strings.write_string(builder, "</mn>")
        
	case ^Subscript_Expr:

	case ^Superscript_Expr:
        strings.write_string(builder, "<msup>")
        build_expr(builder, expr_var.base_expr)
        build_expr(builder, expr_var.super_expr)
        strings.write_string(builder, "</msup>")
	
	case ^Operator_Expr:
		strings.write_string(builder, "<mo>")
		strings.write_byte(builder, expr_var.op)
		strings.write_string(builder, "</mo>")

	case ^Row_Expr:
		strings.write_string(builder, "<row>")
        build_expr(builder, expr_var.row_expr)
        strings.write_string(builder, "</row>")
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