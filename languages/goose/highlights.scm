; Goose syntax highlighting for Zed.
;
; Capture names are Zed's (the grammar's own query in
; tree-sitter-goose/queries/highlights.scm uses nvim-style names). Later
; patterns win where two cover the same bytes, so broad rules come first.

(identifier) @variable

; The implicit parameter of a function value without a parameter list.
((identifier) @variable.special
 (#eq? @variable.special "it"))

(self) @variable.special
(wildcard_pattern) @variable.special

(parameter name: (identifier) @variable.parameter)
(function_value_parameter name: (identifier) @variable.parameter)

; Fields, and the name in `Name { field: value }`.
(field_declaration name: (identifier) @property)
(field_expression field: (identifier) @property)
(field_initializer name: (identifier) @property)

; Modules and namespaces.
(namespace_declaration name: (identifier) @namespace)
(import_path (identifier) @namespace)
(scoped_identifier namespace: (identifier) @namespace)

; Functions.
(function_declaration name: (identifier) @function.definition)
(function_declaration name: (scoped_identifier name: (identifier) @function.definition))
(call_expression function: (identifier) @function.call)
(call_expression function: (scoped_identifier name: (identifier) @function.call))
; A call through a dot is a method call or a call of a free function by UFCS.
(call_expression function: (field_expression field: (identifier) @function.method.call))
(return_expression target: (identifier) @function)
(return_expression target: (scoped_identifier name: (identifier) @function))

; Types.
(struct_declaration name: (identifier) @type.definition)
(struct_declaration name: (scoped_identifier name: (identifier) @type.definition))
(enum_declaration name: (identifier) @type.definition)
(enum_declaration name: (scoped_identifier name: (identifier) @type.definition))
(type_alias_declaration name: (identifier) @type.definition)
(type_alias_declaration name: (scoped_identifier name: (identifier) @type.definition))
(type_parameter name: (identifier) @type)
(named_type name: (identifier) @type)
(named_type name: (scoped_identifier name: (identifier) @type))
(struct_literal name: (identifier) @type)
(struct_literal name: (scoped_identifier name: (identifier) @type))
(primitive_type) @type.builtin

; Enum variants.
(enum_variant name: (identifier) @constant @variant)
(variant_type variant: (identifier) @constant @variant)
(struct_literal variant: (identifier) @constant @variant)
(variant_pattern variant: (identifier) @constant @variant)
(pattern_list (identifier) @constant @variant)
(range_pattern (identifier) @constant @variant)
(negative_pattern (identifier) @constant @variant)

; A payload-less variant: `Shape.Dot`. Types and variants are PascalCase by
; convention, which separates them from a field read.
((field_expression value: (identifier) @type field: (identifier) @constant @variant)
 (#match? @type "^[A-Z]")
 (#match? @constant "^[A-Z]"))

(function_modifier) @keyword

[
  "fn"
  "thread_fn"
  "struct"
  "enum"
  "type"
  "let"
  "var"
  "const"
  "pad"
  "reusable"
  "namespace"
  "defer"
  "fields"
  "variants"
  "types"
  "in"
  "upto"
] @keyword

"as" @operator

[
  "import"
  "from"
] @keyword

[
  "if"
  "else"
  "match"
  "guard"
  "while"
  "for"
  "loop"
  "break"
  (continue_expression)
  "return"
  "block"
] @keyword.control

(boolean_literal) @boolean
(null) @constant.builtin
(int_literal) @number
(float_literal) @number
(char_literal) @string
(string_literal) @string
(raw_string_literal) @string
(escape_sequence) @string.escape

[
  "=" ".="
  "+" "-" "*" "/" "%"
  "==" "!=" ".==" ".!=" "<" "<=" ">" ">="
  "&&" "||" "!"
  "&" "|" "^" "~" "<<" ">>"
  "+=" "-=" "*=" "/=" "%="
  "&=" "|=" "^=" "<<=" ">>="
  "++" "--"
  "->" "=>"
  ".."
  "?"
] @operator

[
  "(" ")" "[" "]" "{" "}"
] @punctuation.bracket

[
  "," ";" ":" "::" "."
] @punctuation.delimiter

; Builtins at the end, so they win over the generic call/identifier patterns.
((identifier) @function.builtin
 (#any-of? @function.builtin
   "print" "str" "format" "assert" "abort" "exit" "hardware_threads"
   "thread_spawn" "thread_wait" "qput" "qget" "qpoll" "default" "copy"
   "to_bytes" "bytes_of" "from_bytes" "embed_shader" "embed_file" "index_of"
   "push" "append" "pop" "pop_n" "resize" "clear" "alloc_index" "alloc_ref"
   "free" "alloc_slice" "realloc_slice" "free_slice"))

(line_comment) @comment
(block_comment) @comment
