import Foundation

/// Flagship: "Code my first website" — HTML → CSS → a real one-page site, published.
enum CuratedWebsite {
    static let flagship = Flagship(
        id: "website",
        title: "Your first website",
        tagline: "From a blank file to your own page on the internet.",
        symbol: "chevron.left.forwardslash.chevron.right",
        tint: .sky,
        category: .code,
        strong: ["html", "css", "website", "webpage", "websites"],
        keywords: ["code", "coding", "programming", "web", "site", "developer", "frontend", "homepage", "portfolio"],
        excludes: ["python", "java", "swift", "kotlin", "rust", "sql", "excel", "wordpress", "shopify", "c++", "golang", "unity"],
        phrases: ["first website", "own website", "build a website", "make a website", "web development", "web design", "web page", "code my"],
        units: [
            Flagship.Unit(title: "Hello, HTML", outcome: "Write a real HTML page with headings, text, lists and links", tint: .sky, nodes: [
                .init(title: "How the web works", brief: "Browser asks a server for a file; the file is HTML. HTML = structure, CSS = style, JavaScript = behaviour (skeleton, clothes, muscles).",
                      kind: .story, symbol: "globe", content: howTheWebWorks),
                .init(title: "Your first tag", brief: "Tags: <h1> heading, <p> paragraph. Opening and closing tags wrap content; the closing tag has a slash. Write your first heading.",
                      kind: .lesson, symbol: "chevron.left.forwardslash.chevron.right", content: firstTag),
                .init(title: "Page skeleton", brief: "Every page: <!DOCTYPE html>, <html>, <head> (title, meta charset) and <body> (what you see). Build the skeleton from memory.",
                      kind: .practice, symbol: "square.stack.3d.up.fill", content: skeleton),
                .init(title: "Treasure chest", brief: "A reward for your first page.", kind: .chest, symbol: "gift.fill", content: .none),
                .init(title: "Lists and links", brief: "<ul>/<ol> with <li> items; links with <a href=\"…\">. Attributes add information to a tag.",
                      kind: .lesson, symbol: "link", content: listsAndLinks),
                .init(title: "Sketch your site", brief: "Mission: sketch your one-page website on paper — header, about you, a list, links. Proof: a photo of the sketch.",
                      kind: .mission, symbol: "pencil.and.ruler.fill", content: sketchMission),
                .init(title: "HTML boss", brief: "Boss battle on tags, page structure, lists and links.", kind: .boss, symbol: "crown.fill", content: htmlBoss),
            ]),
            Flagship.Unit(title: "Make it pretty", outcome: "Style your page with colours, fonts, spacing and classes", tint: .lavender, nodes: [
                .init(title: "Meet CSS", brief: "CSS rules: selector { property: value; }. Add CSS with a <style> tag or a linked stylesheet. The cascade: later rules win.",
                      kind: .lesson, symbol: "paintbrush.fill", content: .seed(meetCSS)),
                .init(title: "Colours and fonts", brief: "color, background-color, hex codes like #8FA8F7, font-family with fallbacks, font-size in px or rem.",
                      kind: .practice, symbol: "paintpalette.fill", content: .seed(colorsAndFonts)),
                .init(title: "The box model", brief: "Every element is a box: content, padding, border, margin. Total width = width + padding + border (unless box-sizing: border-box).",
                      kind: .lesson, symbol: "square.dashed", content: .seed(boxModel)),
                .init(title: "Treasure chest", brief: "A reward for your style.", kind: .chest, symbol: "gift.fill", content: .none),
                .init(title: "Classes", brief: "The class attribute groups elements; .card { } styles them all. Use ids sparingly.",
                      kind: .practice, symbol: "tag.fill", content: .seed(classes)),
                .init(title: "Debug with ilo", brief: "Live call: describe a bug in your page out loud and reason through the fix with ilo.",
                      kind: .call, symbol: "phone.fill", content: .seed(debugCall)),
                .init(title: "CSS boss", brief: "Boss battle on CSS rules, colours, the box model and classes.", kind: .boss, symbol: "crown.fill",
                      content: .review(intro: "CSS boss! Selectors, colours, boxes — let's style.")),
            ]),
            Flagship.Unit(title: "Ship it", outcome: "Build a one-page personal site and put it on the internet", tint: .mint, nodes: [
                .init(title: "Images", brief: "<img src=\"…\" alt=\"…\">: a void element (no closing tag). Alt text describes the image for screen readers and when it fails to load.",
                      kind: .lesson, symbol: "photo.fill", content: .seed(images)),
                .init(title: "Layout with flexbox", brief: "display: flex on a parent lines children up in a row; justify-content, align-items and gap control spacing.",
                      kind: .practice, symbol: "rectangle.split.3x1.fill", content: .seed(flexbox)),
                .init(title: "The broken page", brief: "Story: Mia's page looks wrong; she debugs missing closing tags, a typo in a property and a missing semicolon.",
                      kind: .story, symbol: "ant.fill", content: .seed(brokenPage)),
                .init(title: "Quick review", brief: "Spaced review of HTML and CSS so far.", kind: .review, symbol: "arrow.triangle.2.circlepath",
                      content: .review(intro: "Quick review — HTML and CSS, mixed.")),
                .init(title: "Treasure chest", brief: "A reward before launch.", kind: .chest, symbol: "gift.fill", content: .none),
                .init(title: "Go live", brief: "Mission: publish your page free with Netlify Drop or GitHub Pages; the main file must be called index.html.",
                      kind: .mission, symbol: "paperplane.fill", content: .seed(goLive)),
                .init(title: "Website boss", brief: "The final boss: everything from tags to publishing.", kind: .boss, symbol: "crown.fill",
                      content: .review(intro: "Final boss! Tags, styles, layout, launch. Show ilo you're a web builder.")),
            ]),
        ],
        sources: [
            CourseSource(title: "MDN Web Docs — HTML", url: "https://developer.mozilla.org/en-US/docs/Web/HTML"),
            CourseSource(title: "MDN Web Docs — CSS", url: "https://developer.mozilla.org/en-US/docs/Web/CSS"),
            CourseSource(title: "web.dev — Learn HTML", url: "https://web.dev/learn/html"),
            CourseSource(title: "GitHub Pages", url: "https://pages.github.com"),
        ],
        researchNotes: ["Choosing HTML + CSS first (no frameworks)", "Planning hands-on code labs", "Finding a free way to publish"]
    )

    // MARK: - Unit 1 (hand-written)

    static var howTheWebWorks: Flagship.Content {
        .lesson(intro: "Before we write code: what actually happens when you open a website?", modules: [
            .story("How the web works", [
                storyCard("You type an address", "When you open a site, your browser sends a request across the internet to a computer called a server.", "network", .curious, highlight: "a server"),
                storyCard("The server sends a file", "The server replies with a text file written in HTML. Your browser reads it and draws the page.", "doc.text.fill", .attentive, highlight: "HTML"),
                storyCard("Three languages", "HTML is the skeleton (structure). CSS is the clothes (style). JavaScript is the muscles (behaviour).", "figure.stand", .happy, highlight: "skeleton"),
                storyCard("It all started in 1991", "Tim Berners-Lee put the first website online at CERN in 1991. It was plain HTML — just like yours will be.", "sparkles", .excited),
            ]),
            .match("Match each language to its job", [("HTML", "Structure — the skeleton"), ("CSS", "Style — the clothes"), ("JavaScript", "Behaviour — the muscles"), ("Server", "Sends files to your browser")]),
            .estimate("In what year did the first website go online?", min: 1970, max: 2010, answer: 1991, unit: "",
                      why: "Tim Berners-Lee's first website went live at CERN in 1991."),
            .mcq("What does a browser receive when it asks for a web page?", ["A picture of the page", "An HTML text file", "A video", "An app"], 1,
                 why: "Pages arrive as HTML text; the browser turns it into what you see."),
            .sort("HTML or CSS?", buckets: ["HTML (structure)", "CSS (style)"],
                  [("A heading", 0), ("Make the heading blue", 1), ("A list of hobbies", 0), ("Bigger font size", 1), ("A link to Instagram", 0), ("Space around a photo", 1)],
                  why: "HTML says what things are; CSS says how they look."),
            .tf("True or false?", [
                ("HTML stands for HyperText Markup Language.", true, "Markup = tags that label content."),
                ("You need expensive software to write HTML.", false, "Any text editor works."),
                ("CSS controls how a page looks.", true, "Colours, fonts, spacing, layout."),
            ]),
            .flash("Recap", [("HTML", "Structure (skeleton)"), ("CSS", "Style (clothes)"), ("JavaScript", "Behaviour (muscles)"), ("Server", "Sends the HTML file")]),
        ], takeaways: ["Browsers request files from servers.", "HTML = structure, CSS = style, JS = behaviour."])
    }

    static var firstTag: Flagship.Content {
        .lesson(intro: "Your first line of real code, coming up. It starts with a tag.", modules: [
            .story("Tags", [
                storyCard("Tags label content", "HTML wraps content in tags. <h1> means 'main heading', <p> means 'paragraph'.", "tag.fill", .curious, highlight: "<h1>"),
                storyCard("Open and close", "Most tags come in pairs: <p>Hello</p>. The closing tag has a slash: </p>.", "chevron.left.forwardslash.chevron.right", .attentive, highlight: "</p>"),
                storyCard("Six heading sizes", "<h1> is the biggest and most important heading. <h2> to <h6> are smaller sub-headings.", "textformat.size", .happy),
            ]),
            .code("Write a main heading that says Hello, world!", language: "html", starter: "<!-- your heading here -->\n",
                  mustContain: ["<h1>", "</h1>"], solution: "<h1>Hello, world!</h1>", why: "<h1> opens the heading, </h1> closes it.", title: "Your first tag"),
            .mcq("Which is a correct paragraph?", ["<p>Hi there<p>", "<p>Hi there</p>", "</p>Hi there<p>", "<paragraph>Hi there</paragraph>"], 1,
                 why: "Opening tag, content, closing tag with a slash."),
            .blank("A closing tag starts with <___.", ["/", "!", "#", "?"], 0, why: "The slash marks the end: </p>."),
            .spot("Tap the lines with mistakes", ["<h1>My page</h1>", "<p>I love salsa<p>", "<h2>Hobbies</h2>", "<p>Cooking</h1>"],
                  wrong: [1, 3], why: "Line 2 never closes the <p> (missing slash), and line 4 closes with the wrong tag."),
            .code("Add a paragraph under the heading that introduces you.", language: "html", starter: "<h1>Hi, I'm Sam</h1>\n",
                  mustContain: ["<p>", "</p>"], solution: "<h1>Hi, I'm Sam</h1>\n<p>I'm learning to build websites.</p>", title: "Add a paragraph"),
            .flash("Recap", [("<h1>", "Main heading"), ("<p>", "Paragraph"), ("</p>", "Closing tag"), ("<h2>–<h6>", "Smaller headings")]),
        ], takeaways: ["Tags wrap content: <p>…</p>.", "Closing tags have a slash.", "<h1> is the main heading."])
    }

    static var skeleton: Flagship.Content {
        .lesson(intro: "Every web page on Earth has the same skeleton. Let's build it.", modules: [
            .story("The page skeleton", [
                storyCard("<!DOCTYPE html>", "The first line tells the browser: this is a modern HTML page.", "1.circle.fill", .attentive),
                storyCard("<html>", "Wraps everything else. Think of it as the page's outline.", "square.dashed", .curious),
                storyCard("<head>", "Info ABOUT the page that isn't shown on it: the <title> in the browser tab, and <meta charset=\"utf-8\"> so emoji and accents work.", "info.circle.fill", .happy, highlight: "isn't shown"),
                storyCard("<body>", "Everything visible: headings, paragraphs, images, links.", "eye.fill", .proud, highlight: "Everything visible"),
            ]),
            .order("Put the skeleton in order", ["<!DOCTYPE html>", "<html>", "<head>", "<title>My page</title>", "</head>", "<body>", "</body>", "</html>"],
                   why: "Doctype first, then html containing head (info) and body (content)."),
            .code("Complete the skeleton: add a <title> inside head and an <h1> inside body.", language: "html",
                  starter: "<!DOCTYPE html>\n<html>\n  <head>\n    \n  </head>\n  <body>\n    \n  </body>\n</html>",
                  mustContain: ["<title>", "</title>", "<h1>"],
                  solution: "<!DOCTYPE html>\n<html>\n  <head>\n    <title>My page</title>\n  </head>\n  <body>\n    <h1>Welcome!</h1>\n  </body>\n</html>",
                  why: "The title goes in the tab (head); the heading goes on the page (body).", title: "Build the skeleton"),
            .mcq("Where does the <title> tag go?", ["Inside <body>", "Inside <head>", "After </html>", "Anywhere"], 1, why: "<title> is information about the page, so it lives in <head>."),
            .highlight("Tap the lines that show up ON the page", ["<title>My portfolio</title>", "<h1>Hi, I'm Sam</h1>", "<meta charset=\"utf-8\">", "<p>I make websites.</p>", "<!DOCTYPE html>"],
                       find: [1, 3], why: "Only content inside <body> — like headings and paragraphs — appears on the page."),
            .blank("Visible content goes inside the <___> tag.", ["body", "head", "title", "meta"], 0),
            .speed("Skeleton sprint", seconds: 25, [
                ("<!DOCTYPE html> is the first line.", true, "It declares a modern HTML page."),
                ("<title> text appears in the browser tab.", true, "Not on the page itself."),
                ("<head> holds the visible content.", false, "That's <body>."),
                ("<meta charset=\"utf-8\"> helps accents and emoji display.", true, "It sets the character encoding."),
            ]),
        ], takeaways: ["Doctype → html → head + body.", "Head = info about the page; body = what you see."])
    }

    static var listsAndLinks: Flagship.Content {
        .lesson(intro: "Lists organise, links connect. Together they're half the web.", modules: [
            .story("Lists and links", [
                storyCard("Bullet lists", "<ul> makes an unordered (bulleted) list. Each item is an <li>.", "list.bullet", .attentive, highlight: "<ul>"),
                storyCard("Numbered lists", "<ol> makes an ordered (numbered) list — perfect for steps and top-5s.", "list.number", .curious, highlight: "<ol>"),
                storyCard("Links", "<a href=\"https://example.com\">Click me</a>. The href attribute holds the address; the text between the tags is what you click.", "link", .happy, highlight: "href"),
                storyCard("Attributes", "Attributes add info to a tag: name=\"value\" inside the opening tag. href, src, alt and class are the ones you'll use most.", "tag.fill", .proud),
            ]),
            .match("Match the tag to its job", [("<ul>", "Bulleted list"), ("<ol>", "Numbered list"), ("<li>", "One list item"), ("<a>", "A link")]),
            .code("Make a bulleted list of 3 things you love.", language: "html", starter: "<h2>Things I love</h2>\n",
                  mustContain: ["<ul>", "<li>", "</ul>"], solution: "<h2>Things I love</h2>\n<ul>\n  <li>Salsa</li>\n  <li>Pizza</li>\n  <li>Sunsets</li>\n</ul>",
                  title: "Your first list"),
            .bricks("Build a link to example.com", ["<a", "href=\"https://example.com\">", "Example", "</a>"], distractors: ["<link>", "src=", "</href>"],
                    why: "Opening <a> with an href attribute, the clickable text, then </a>."),
            .mcq("Which attribute holds a link's address?", ["src", "href", "alt", "link"], 1, why: "href = hypertext reference."),
            .code("Add a link to your favourite website.", language: "html", starter: "<p>My favourite site: </p>",
                  mustContain: ["<a", "href=", "</a>"], solution: "<p>My favourite site: <a href=\"https://wikipedia.org\">Wikipedia</a></p>", title: "Your first link"),
            .flash("Recap", [("<ul>", "Bulleted list"), ("<ol>", "Numbered list"), ("<li>", "List item"), ("<a href=\"…\">", "Link")]),
        ], takeaways: ["<ul>/<ol> hold <li> items.", "Links: <a href=\"address\">text</a>.", "Attributes live in the opening tag."])
    }

    static var sketchMission: Flagship.Content {
        .lesson(intro: "Pros sketch before they code. Grab paper — let's design your page.", modules: [
            .story("Sketch first", [
                storyCard("Why paper?", "A 5-minute sketch saves an hour of code. You decide WHAT goes on the page before HOW.", "pencil.and.scribble", .curious),
                storyCard("A classic one-pager", "Header with your name → a short 'about me' → a list (hobbies, projects) → links to find you.", "rectangle.split.1x2.fill", .happy),
                storyCard("Boxes, not art", "Draw rectangles and label them. Nobody grades drawing skills here.", "square.dashed", .laughing),
            ]),
            .order("Order a classic one-page site from top to bottom", ["Header with your name", "About me paragraph", "List of hobbies or projects", "Links to contact you"]),
            .sort("Which tag would you use for each part?", buckets: ["<h1>", "<p>", "<ul>"],
                  [("Your name at the top", 0), ("A few sentences about you", 1), ("Your 3 hobbies", 2), ("Your favourite quote", 1), ("Your projects", 2)]),
            .mission("Sketch your site", "Sketch your one-page website on paper.",
                     steps: ["Draw a phone-shaped rectangle", "Add a header box with your name", "Add an 'about me' box and a list box",
                             "Add a row of links at the bottom", "Label each box with the HTML tag you'd use", "Take a photo of your sketch"],
                     proof: "A photo of your website sketch"),
            .free("Describe your page in two sentences: what's on it and who is it for?", rubric: ["Mentions the sections of the page", "Mentions who it's for"],
                  sample: "My page has my name, a short intro, a list of my salsa and cooking projects, and links to my Instagram. It's for friends and future clients.", title: "Your plan"),
            .mcq("Which tag fits the 'links to contact you' section best?", ["<h1>", "<a> inside a list", "<title>", "<head>"], 1),
            .flash("Recap", [("Sketch first", "Decide WHAT before HOW"), ("Header", "<h1> with your name"), ("About", "<p>"), ("Hobbies", "<ul> + <li>")]),
        ], takeaways: ["Sketch before you code.", "Label every box with its tag."])
    }

    static var htmlBoss: Flagship.Content {
        .lesson(intro: "HTML boss! Tags, skeleton, lists and links — at speed.", modules: [
            .speed("Warm-up round", seconds: 30, [
                ("<p> means paragraph.", true, "p for paragraph."),
                ("Closing tags start with a backslash \\.", false, "A forward slash: </p>."),
                ("<title> content shows in the browser tab.", true, "It lives in <head>."),
                ("<ol> makes a bulleted list.", false, "<ol> is numbered; <ul> is bulleted."),
                ("href holds a link's address.", true, "Hypertext reference."),
                ("HTML controls colours and fonts.", false, "That's CSS."),
            ]),
            .code("Fix the page: close the paragraph and the list item.", language: "html",
                  starter: "<h1>Sam's page</h1>\n<p>Hi, I build websites.\n<ul>\n  <li>HTML\n</ul>",
                  mustContain: ["</p>", "</li>"], solution: "<h1>Sam's page</h1>\n<p>Hi, I build websites.</p>\n<ul>\n  <li>HTML</li>\n</ul>",
                  why: "Every opened tag (except void tags like <img>) needs its closing partner.", title: "Fix it"),
            .mcq("Which line correctly links to MDN?", ["<a src=\"https://developer.mozilla.org\">MDN</a>", "<a href=\"https://developer.mozilla.org\">MDN</a>",
                                                        "<link>https://developer.mozilla.org</link>", "<a>https://developer.mozilla.org</a href>"], 1),
            .match("Match the part to where it goes", [("<title>", "Inside <head>"), ("<h1>", "Inside <body>"), ("<li>", "Inside <ul> or <ol>"), ("<!DOCTYPE html>", "Very first line")]),
            .spot("Tap the mistakes in this skeleton", ["<!DOCTYPE html>", "<html>", "<body>", "<title>My page</title>", "</body>", "<head></head>", "</html>"],
                  wrong: [3, 5], why: "<title> belongs inside <head>, and <head> must come before <body>."),
            .blank("A numbered list uses the <___> tag.", ["ol", "ul", "li", "nl"], 0),
            .teach("Teach ilo the difference between <head> and <body>.", rubric: ["Head holds info about the page (like the title)", "Body holds the visible content"],
                   sample: "The head holds information about the page that you don't see on it, like the title in the tab. The body holds everything you see: headings, text, images and links."),
            .speed("Final round", seconds: 25, [
                ("Attributes go inside the opening tag.", true, "name=\"value\"."),
                ("<li> items go inside <ul> or <ol>.", true, "That's what makes them a list."),
                ("The first website went online in 1991.", true, "At CERN."),
                ("<body> content is invisible.", false, "Body is what you see."),
            ]),
        ], takeaways: ["You can build a full HTML page from scratch.", "Open and close every tag."])
    }

    // MARK: - Unit 2

    static let meetCSS = KnowledgeSeed(
        intro: "Time to make it pretty. CSS is how.",
        cards: [
            storyCard("A CSS rule", "h1 { color: navy; } — a selector (h1), then a property (color) and a value (navy) inside curly braces.", "paintbrush.fill", .curious, highlight: "selector"),
            storyCard("Semicolons matter", "Each property: value pair ends with a semicolon. Forget one and the next line may silently break.", "exclamationmark.triangle.fill", .suspicious, highlight: "semicolon"),
            storyCard("Where CSS lives", "Inside a <style> tag in the head, or in a separate file linked with <link rel=\"stylesheet\" href=\"style.css\">.", "doc.fill", .attentive),
            storyCard("The cascade", "If two rules target the same thing equally, the later one wins. That's the 'cascading' in Cascading Style Sheets.", "arrow.down.to.line", .happy, highlight: "the later one wins"),
        ],
        questions: [
            .q("In `p { color: red; }`, what is `p`?", ["The property", "The selector", "The value"], 1, "The selector chooses which elements the rule styles."),
            .q("Two equal rules set h1 to blue, then to green. What colour is h1?", ["Blue", "Green", "Both"], 1, "Later rules win in the cascade."),
        ],
        statements: [.s("CSS stands for Cascading Style Sheets.", true), .s("CSS rules use square brackets.", false, "Curly braces { }."),
                     .s("Each declaration ends with a semicolon.", true), .s("A <link> tag can connect an external stylesheet.", true)],
        pairs: [.p("Selector", "What to style"), .p("Property", "What to change"), .p("Value", "How to change it"), .p("Cascade", "Later rules win")],
        blanks: [.b("h1 { color: navy___ }", [";", ":", ","], 0, "Declarations end with a semicolon.")],
        practice: [.code("Make every paragraph dark grey.", language: "css", starter: "p {\n  \n}", mustContain: ["color:", ";"],
                         solution: "p {\n  color: #333333;\n}", why: "The color property sets text colour.", title: "Your first rule")],
        takeaways: ["selector { property: value; }", "Later rules win (the cascade)."]
    )

    static let colorsAndFonts = KnowledgeSeed(
        intro: "Colour and type: 80% of 'looks professional' comes from these two.",
        cards: [
            storyCard("Hex colours", "#RRGGBB: two hex digits each for red, green, blue. #FF0000 is pure red; #8FA8F7 is ilo's periwinkle.", "paintpalette.fill", .excited, highlight: "#RRGGBB"),
            storyCard("Text vs background", "color sets the text colour. background-color sets the fill behind it. Keep strong contrast so it's readable.", "circle.lefthalf.filled", .attentive, highlight: "contrast"),
            storyCard("Fonts with fallbacks", "font-family: \"Helvetica\", Arial, sans-serif; — if the first font is missing, the browser tries the next.", "textformat", .curious, highlight: "tries the next"),
        ],
        questions: [
            .q("What colour is #00FF00?", ["Red", "Green", "Blue"], 1, "RRGGBB: the middle pair is green."),
            .q("Which property sets the colour behind text?", ["color", "background-color", "font-color"], 1),
        ],
        statements: [.s("#FFFFFF is white.", true), .s("font-color is a CSS property.", false, "It's just color."), .s("Low contrast text is harder to read.", true)],
        pairs: [.p("color", "Text colour"), .p("background-color", "Fill colour"), .p("font-family", "Typeface"), .p("font-size", "Text size")],
        blanks: [.b("Pure red in hex is #___.", ["FF0000", "00FF00", "0000FF"], 0)],
        practice: [.code("Give the page a periwinkle background and white text.", language: "css", starter: "body {\n  \n}",
                         mustContain: ["background", "color"], solution: "body {\n  background-color: #8FA8F7;\n  color: white;\n}", title: "Colour it")],
        takeaways: ["Hex colours are #RRGGBB.", "color = text, background-color = fill.", "Always give fonts a fallback."]
    )

    static let boxModel = KnowledgeSeed(
        intro: "Everything on a web page is a box. Master the box, master the layout.",
        cards: [
            storyCard("Four layers", "From inside out: content, padding (space inside), border, margin (space outside).", "square.dashed", .curious, highlight: "content, padding"),
            storyCard("Padding vs margin", "Padding pushes the border away from the content. Margin pushes other elements away from the border.", "arrow.left.and.right.square", .attentive),
            storyCard("The width surprise", "By default, width sets only the content. Padding and border are added on top.", "exclamationmark.triangle.fill", .surprised, highlight: "added on top"),
            storyCard("The fix", "box-sizing: border-box; makes width include padding and border. Most developers turn it on everywhere.", "checkmark.seal.fill", .proud),
        ],
        questions: [
            .q("Which layer is the space OUTSIDE the border?", ["Padding", "Margin", "Content"], 1),
            .q("What does box-sizing: border-box do?", ["Adds a border", "Makes width include padding and border", "Removes margins"], 1),
        ],
        statements: [.s("Padding is inside the border.", true), .s("Margin is part of the element's background.", false, "Margin is transparent space outside."),
                     .s("By default, padding makes a box wider than its width value.", true)],
        pairs: [.p("Content", "The text or image"), .p("Padding", "Space inside the border"), .p("Border", "The edge line"), .p("Margin", "Space outside the border")],
        sequencePrompt: "Order the box from inside to outside",
        sequence: ["Content", "Padding", "Border", "Margin"],
        blanks: [.b("Space inside the border is called ___.", ["padding", "margin", "gap"], 0)],
        practice: [.estimate("A box has width: 200px, padding: 20px and border: 5px (default box-sizing). How wide is it on screen, border to border?",
                             min: 150, max: 300, answer: 250, unit: "px", why: "200 + 20×2 padding + 5×2 border = 250px.")],
        takeaways: ["Content → padding → border → margin.", "Use box-sizing: border-box to keep widths predictable."]
    )

    static let classes = KnowledgeSeed(
        intro: "Style many things at once — without repeating yourself.",
        cards: [
            storyCard("The class attribute", "<p class=\"card\"> gives an element a label. Many elements can share the same class.", "tag.fill", .curious, highlight: "class=\"card\""),
            storyCard("The dot selector", ".card { … } styles every element with class=\"card\". The dot means 'class'.", "circle.fill", .attentive, highlight: "The dot means 'class'"),
            storyCard("Ids are unique", "id=\"hero\" and #hero { } target ONE element. Prefer classes for styling.", "number", .happy),
        ],
        questions: [
            .q("Which selector targets class=\"note\"?", ["#note", ".note", "note", "*note"], 1),
            .q("How many elements can share one class?", ["Only one", "As many as you like", "Exactly two"], 1),
        ],
        statements: [.s("A dot selects a class in CSS.", true), .s("An id can be used on many elements.", false, "Ids should be unique."), .s("One element can have several classes.", true)],
        pairs: [.p(".card", "Class selector"), .p("#hero", "Id selector"), .p("p", "Element selector"), .p("class=\"…\"", "HTML attribute")],
        blanks: [.b("In CSS, a class selector starts with a ___.", ["dot", "hash", "slash"], 0)],
        practice: [
            .code("Give the paragraph the class \"highlight\".", language: "html", starter: "<p>Read this first!</p>", mustContain: ["class=", "highlight"],
                  solution: "<p class=\"highlight\">Read this first!</p>", title: "Add a class"),
            .code("Style the .highlight class with a yellow background.", language: "css", starter: "/* style the highlight class */\n",
                  mustContain: [".highlight", "background"], solution: ".highlight {\n  background-color: #FFE066;\n}", title: "Style the class"),
        ],
        takeaways: ["class=\"name\" in HTML, .name in CSS.", "Prefer classes over ids for styling."]
    )

    static let debugCall = KnowledgeSeed(
        intro: "Rubber-duck time: explaining a bug out loud often solves it.",
        cards: [
            storyCard("Rubber duck debugging", "Programmers explain their code line by line to a rubber duck. Saying it out loud reveals the mistake.", "bubble.left.fill", .laughing),
            storyCard("Describe, then guess", "Say what you expected, what happened instead, and your best guess why.", "questionmark.circle.fill", .attentive),
        ],
        questions: [.q("What's the first step when your CSS doesn't apply?", ["Rewrite everything", "Check the selector matches and every line ends with a semicolon", "Give up"], 1)],
        statements: [.s("Explaining a bug out loud can help you find it.", true), .s("Browsers show a big error when CSS is wrong.", false, "CSS usually fails silently.")],
        pairs: [.p("Expected", "What should happen"), .p("Actual", "What happened"), .p("Guess", "Why it might differ"), .p("Test", "Try one fix")],
        practice: [.call("ilo, your debugging buddy", goal: "Describe a CSS bug (expected vs actual) and reason out a fix",
                         opening: "Hey! My heading should be blue but it's still black. Want to debug it with me? What would you check first?", turns: 4)],
        takeaways: ["Expected → actual → guess → test.", "CSS fails silently — check selectors and semicolons."]
    )

    // MARK: - Unit 3

    static let images = KnowledgeSeed(
        intro: "A page without pictures is a letter. Let's add images — the right way.",
        cards: [
            storyCard("The img tag", "<img src=\"me.jpg\" alt=\"Sam dancing salsa\"> — src is the file, alt describes it.", "photo.fill", .happy, highlight: "alt describes it"),
            storyCard("No closing tag", "<img> is a void element: it has no content, so it never gets a </img>.", "xmark.circle.fill", .curious, highlight: "void element"),
            storyCard("Why alt matters", "Screen readers read alt text aloud to blind users, and it shows if the image fails to load.", "accessibility", .proud),
        ],
        questions: [
            .q("Which attribute tells the browser which image file to show?", ["alt", "src", "href"], 1),
            .q("Best alt text for a photo of you dancing?", ["\"image\"", "\"Sam dancing salsa at a wedding\"", "\"IMG_2041.jpg\""], 1, "Describe what the image shows."),
        ],
        statements: [.s("<img> needs a closing </img> tag.", false, "It's a void element."), .s("Alt text helps screen-reader users.", true), .s("src holds the image's address.", true)],
        pairs: [.p("src", "Image file"), .p("alt", "Description"), .p("Void element", "No closing tag"), .p("Screen reader", "Reads alt text aloud")],
        blanks: [.b("<img> is a ___ element, so it has no closing tag.", ["void", "block", "secret"], 0)],
        practice: [.code("Add an image of a cat with good alt text.", language: "html", starter: "<h2>My cat</h2>\n",
                         mustContain: ["<img", "src=", "alt="], solution: "<h2>My cat</h2>\n<img src=\"cat.jpg\" alt=\"A ginger cat asleep in the sun\">", title: "Add an image")],
        takeaways: ["<img src=\"…\" alt=\"…\"> — no closing tag.", "Always describe images with alt."]
    )

    static let flexbox = KnowledgeSeed(
        intro: "Flexbox: the easiest way to put things side by side.",
        cards: [
            storyCard("Flex the parent", "Put display: flex; on a container and its children line up in a row.", "rectangle.split.3x1.fill", .excited, highlight: "display: flex;"),
            storyCard("Spread them out", "justify-content controls the main axis: flex-start, center, space-between…", "arrow.left.and.right", .attentive),
            storyCard("Line them up", "align-items controls the cross axis (vertical in a row). gap adds space between children.", "arrow.up.and.down", .curious, highlight: "gap"),
        ],
        questions: [
            .q("Where do you put display: flex?", ["On each child", "On the parent container", "On the body only"], 1),
            .q("Which property adds space between flex children?", ["margin-between", "gap", "space"], 1),
        ],
        statements: [.s("display: flex lines children up in a row by default.", true), .s("justify-content: center centres items along the main axis.", true),
                     .s("Flexbox only works on images.", false)],
        pairs: [.p("display: flex", "Turns on flexbox"), .p("justify-content", "Main-axis spacing"), .p("align-items", "Cross-axis alignment"), .p("gap", "Space between items")],
        blanks: [.b("To centre items in a flex row, use justify-content: ___;", ["center", "middle", "flex"], 0)],
        practice: [.code("Make the .links container a centred flex row with a 16px gap.", language: "css", starter: ".links {\n  \n}",
                         mustContain: ["display", "flex", "center", "gap"], solution: ".links {\n  display: flex;\n  justify-content: center;\n  gap: 16px;\n}",
                         title: "Flex it")],
        takeaways: ["display: flex on the parent.", "justify-content, align-items and gap do the rest."]
    )

    static let brokenPage = KnowledgeSeed(
        intro: "Story: Mia's first page is broken, and she has 10 minutes before showing it to her class.",
        cards: [
            storyCard("Panic", "Mia's whole page turned into one giant heading. Her heart sank.", "exclamationmark.triangle.fill", .scared),
            storyCard("Clue #1", "She found it: <h1>Mia's page<h1> — the closing tag was missing its slash, so the heading never ended.", "magnifyingglass", .curious, highlight: "missing its slash"),
            storyCard("Clue #2", "Her background wasn't changing. She'd typed backround-color. One missing letter — CSS silently ignored it.", "textformat.abc", .confused),
            storyCard("Fixed", "Two tiny fixes, page perfect. Mia learned the #1 debugging rule: check the small stuff first.", "checkmark.seal.fill", .proud, highlight: "check the small stuff first"),
        ],
        questions: [
            .q("Why did Mia's whole page become a heading?", ["Her CSS was wrong", "The <h1> was never closed", "Her browser was old"], 1),
            .q("What happens when you misspell a CSS property?", ["The page crashes", "The browser ignores that line", "It autocorrects"], 1),
        ],
        statements: [.s("Browsers show an error when CSS is misspelled.", false, "They silently ignore it."), .s("A missing closing tag can affect everything after it.", true)],
        sequencePrompt: "Order Mia's debugging",
        sequence: ["Notice what looks wrong", "Find the element causing it", "Check tags and spelling", "Fix one thing", "Reload and check"],
        blanks: [.b("The #1 debugging rule: check the ___ stuff first.", ["small", "big", "hard"], 0)],
        scenario: .scenario("Your page looks broken 5 minutes before you share it. What do you do first?", ["Delete it and start over", "Check the last thing you changed, then tags and spelling", "Share it anyway"], 1,
                            consequences: ["You lose all your work for a probably-tiny bug.", "Most bugs hide in the last change — you'll likely find it in a minute.", "Everyone sees the giant heading."],
                            why: "Start with the most recent change and the small stuff."),
        practice: [.spot("Tap the lines with bugs", ["<h1>Mia's page</h1>", "<p>Hi!</p>", "body { backround-color: pink; }", "p { color: navy }", "h1 { font-size: 40px; }"],
                         wrong: [2], why: "backround-color is misspelled, so the browser ignores it. (A missing semicolon on the LAST declaration is actually allowed.)")],
        takeaways: ["Unclosed tags break everything after them.", "Misspelled CSS is silently ignored.", "Check the small stuff first."]
    )

    static let goLive = KnowledgeSeed(
        intro: "Launch day. Your page is about to be on the actual internet.",
        cards: [
            storyCard("index.html", "Name your main file index.html — servers show it by default when someone visits your address.", "doc.fill", .attentive, highlight: "index.html"),
            storyCard("Netlify Drop", "The fastest way: open app.netlify.com/drop and drag your site's folder onto the page. You get a live link in seconds.", "tray.and.arrow.up.fill", .excited),
            storyCard("GitHub Pages", "The classic way: put your files in a GitHub repository and turn on Pages in the settings. Free, forever.", "globe", .happy),
        ],
        questions: [
            .q("What should your main page file be called?", ["home.html", "index.html", "main.html"], 1, "Servers look for index.html by default."),
            .q("Which of these is a free way to publish a static site?", ["GitHub Pages", "Emailing the file", "Printing it"], 0),
        ],
        statements: [.s("You need to buy a server to publish a simple website.", false, "Free static hosting is everywhere."), .s("index.html is shown by default.", true)],
        sequencePrompt: "Order your launch",
        sequence: ["Put your files in one folder", "Name the main file index.html", "Upload the folder to a host", "Open your live link", "Share it with one person"],
        practice: [.mission("Go live", "Publish your page and share the link with one person.",
                            steps: ["Put index.html (and style.css) in one folder", "On a computer, open app.netlify.com/drop (or set up GitHub Pages)",
                                    "Drag the folder in and wait for your link", "Open the link on your phone", "Send it to one friend and screenshot their reply"],
                            proof: "A screenshot of your live website")],
        takeaways: ["Name the main file index.html.", "Netlify Drop or GitHub Pages publish for free."]
    )
}
