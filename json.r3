REBOL[
	Title: "REBOL / JSON converter"
	Author: "Boleslav Brezovsky"
	Date: 30-1-2013
	Version: 0.0.2
	Rights: http://www.apache.org/licenses/LICENSE-2.0
	To-Do: [
		"add more datatypes and object emitter"
		"add support for block! in to-json"
	]
]

json-ctx: context [

stack: here: copy []
pos: copy []
key: "JSON"
type: map!
keyword?: false

;=========RULES

;---JSON rules

entities: charset {"\/bfnrt}
escapes: [#"^"" "^"" #"\" "\" #"/" "/" #"b" "^H" #"f" "^L" #"r" "^M" #"n" "^/" #"t" "^-"]
rescapes: reverse copy escapes
forskip rescapes 2 [rescapes/1: to char! rescapes/1]
rescapes: to map! rescapes
resc: charset extract/index escapes 2 2
hexchars: charset "0123456789ABCDEFabcdef"
whitespace:	charset " ^-^/"
space:		[any whitespace]
object-in:	[space #"{" space]
object-out:	[space #"}" space]
array-in:	[space #"[" space]
array-out:	[space #"]" space]
comma:		[space #"," space]
digits:		charset "0123456789"
exponent:	[[#"e" | #"E"] opt [#"+" | #"-"] some digits]

object: [ object-in (emit-obj) any members object-out (close) ]
members: [ space pair space opt [ comma members ] ]
pair: [ string (key: val) ":" space value ]
array: [ array-in (emit-array) any elements array-out (close) ]
elements: [ value opt [ comma elements ]]
value: [ string (emit-string) | copy val number (emit-number) | object | array | "true" (emit-val true) | "false" (emit-val false) | "null" (emit-val none) ]

string: [ {"} copy val to {"} skip ]
number: [ opt #"-" some digits opt [#"." some digits] opt exponent ]

emit-val: func [
	val
	/deep	"Change HERE position (when inserting object! or map!)"
	/local
][
	if deep [append pos here]
	either key [
		repend here [
			either equal? object! type [to set-word! key][key]
			val
		]
		local: select here either equal? object! type [to word! key][key]
	][
		append here local: val
	]
	if deep [
		here: local
		key: none
	]
	here
]
emit-obj: does [emit-val/deep make :type copy []]
emit-array: does [emit-val/deep copy []]
emit-number: does [emit-val load val]
emit-string: has [uchar] [
	parse/all val [
		any [
			to "\" [
				mark: #"\" [
					entities (change/part mark select escapes mark/2 2)
				|	"u" copy uchar 4 hexchars (change/part mark to-utf-char to integer! load rejoin ["#{" uchar "}"] 6)
				] :mark
			]
		]
		to end
	]
	emit-val val
]
close: does [here: take/last pos]

to-utf-char: use [os fc en][
	os: [0 192 224 240 248 252]
	fc: [1 64 4096 262144 16777216 1073741824]
	en: [127 2047 65535 2097151 67108863 2147483647]

	func [int [integer!] /local char][
		repeat ln 6 [
			if int <= en/:ln [
				char: reduce [os/:ln + to integer! (int / fc/:ln)]
				repeat ps ln - 1 [
					insert next char (to integer! int / fc/:ps) // 64 + 128
				]
				break
			]
		]
		to-string to-binary char
	]
]

set 'load-json func [
	"Load JSON data and convert them to REBOL"
	data	[string!]	"JSON data"
	/as-object			"Return object! instead of map!"
][
	; initalization
	stack: here: copy []
	pos: copy []
	key: none
	type: either as-object [object!][map!]

	unless parse/all data object [
		make error! "This shouldn't happened. Parser returned FALSE."
	]
	first stack
]

;===============

rvalue: [
	mark: [
		[map! | object!] :mark (change/only mark body-of mark/1 emit-jstruct "{}") into robject
	|	block! :mark into rarray
	|	string! (emit-jstring copy mark/1)
	|	logic! (emit-jvalue mold mark/1)
	|	none! (emit-jvalue "none")
	|	any-type! (emit-jstring mold mark/1)
	] (key: none)
]
rarray: [
	(emit-jstruct "[]" key: none )
	some [set val rvalue]
	(close-jstruct)
]
robject: [
	some [
		set key [ any-string! | any-word! ]
		set val rvalue
	]
	(close-jstruct)
]

make-key: func [key][
	key: case [
		set-word? key	[ head remove back tail mold key ]
		none? key		[ key ]
		not string? key	[ mold key ]
		true			[ key ]
	]
	if key [ replace/all key #"-" #"_" ]
	either key [rejoin [{"} key {":}]][""]
]

emit-jvalue: func [value][
	here: insert here rejoin [make-key key value ","]
]
emit-jstring: func [
	string
	/local mk
][
	parse/all string [
		some [
			mk: resc (mk: change/part mk join "\" select rescapes mk/1 1) :mk
		|	skip
		]
	]
	emit-jvalue rejoin [{"} string {"}]
]
emit-jstruct: func [
	bracks
	/local
][
	insert here local: rejoin [make-key key bracks ","]
	here: skip here -2 + length? local
]
close-jstruct: does [
	if equal? #"," first back here [remove back here]	; why not...
	here: next here
]

;==============

set 'to-json func [
	"Return REBOL data as JSON"
	data	[map! object!]	"REBOL data"
	; NOTE: does a deep copy of input. Or should it modify?
][
	stack: here: copy {}
	pos: copy []
	key: none
	parse compose/only [(copy/deep data)] [some rvalue]
	close-jstruct
	head stack
]
; end of JSON-ctx
]
