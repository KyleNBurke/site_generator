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

        result, split_error := strings.split(file_text, "###")
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

        for {
            line, ok := strings.split_lines_iterator(&content)
            if !ok do break

            if strings.starts_with(line, "#") {

            } else if strings.starts_with(line, "##") {
                
            } else {
                strings.write_string(&article_builder, "<p>")
                strings.write_string(&article_builder, line)
                strings.write_string(&article_builder, "</p>")
            }

            strings.write_rune(&article_builder, '\n')
        }

        article_html := strings.to_string(article_builder)

        file_stem := file_info.name[:len(file_info.name) - 3]
        file_name := fmt.tprintf("%s.html", file_stem)
        file_path := fmt.tprintf("site/article/%s", file_name)
        
        write_error := os.write_entire_file(file_path, article_html)
        fmt.assertf(write_error == nil, "Error: %v", write_error)

        article.file_name = file_name
        append(&articles, article)
    }

    // Home page
    articles_builder := strings.builder_make()

    for article in articles {
        line := fmt.aprintfln("<li><a href=\"article/%s\">%s</a></li>", article.file_name, article.title)
        strings.write_string(&articles_builder, line)
    }

    article_links := strings.to_string(articles_builder)
    home_page_text, _ := strings.replace(HOME_PAGE_TEXT, "#articles#", article_links, 1)


    error = os.write_entire_file("site/index.html", home_page_text)
    assert(error == nil)

    os.copy_file("site/style.css", "style.css")
}

HOME_PAGE_TEXT ::
`<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <h1>Kyle Burke</h1>
    <h1>Articles</h1>
    <ul>
        #articles#
    </ul>
</body>
</html>`
