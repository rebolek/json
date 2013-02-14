REBOL[
	Title: "REBOL / JSON converter"
	Author: "Boleslav Brezovsky"
	Date: 30-1-2013
	Version: 0.0.2
	Rights: http://www.apache.org/licenses/LICENSE-2.0
	To-Do: [
		SAVE-JSON
	]
]

do %json.r3
do %altJSON.r3

;==============test

test-data: {{
    "glossary": {
        "title": "example glossary",
		"GlossDiv": {
            "title": "S",
			"GlossList": {
				"GlossEntry": {
					"ID": "SGML",
					"SortAs": "SGML",
					"GlossTerm": "Standard Generalized Markup Language",
					"Acronym": "SGML",
					"Abbrev": "ISO 8879:1986",
					"GlossDef": {
						"para": "A meta-markup language, used to create markup languages such as DocBook.",
						"GlossSeeAlso": ["GML", "XML"]
					},
					"GlossSee": "markup"
                }
            }
        }
    }
}}

test-data2: {{
	"data":[
		{"url":"http\u00253A\u00252F\u00252Fwww.milosnahrad.eu",
		"normalized_url":"http:\/\/www.milosnahrad.eu\/",
		"share_count":15,
		"like_count":15,
		"comment_count":7,
		"total_count":37,
		"commentsbox_count":0,
		"comments_fbid":142533672565391,
		"click_count":0}
	]
}}

test-data3: {{
	"key1":{
		"just": "pair"
	},
	"key2":["val1","val2"],
	"key3":["val3"]
}}

print "1."
probe td1: load-json/as-object test-data2
print "end of part one"

probe dt [loop 100000 [j1: to-json td1]]
probe dt [loop 100000 [j2: save-json td1]]

probe equal? j1 j2