; Goose syntax highlighting for Zed.
;
; Copied from the grammar's own query,
; https://github.com/aardappel/goose/blob/9412b80f52d833c4697cffdbbf1f4eeb5195cd41/tree-sitter/queries/highlights.scm,
; and adapted to Zed's capture names:
;
;   @module           -> @namespace
;   @variable.builtin -> @variable.special
;   @character        -> @string
;   @escape           -> @string.escape
;
; The remaining dotted names (@function.call, @keyword.modifier, …) are kept
; as they are: Zed resolves an unknown capture to its longest parent capture
; that the theme defines, so @function.call falls back to @function. Captures
; written one after another on the same node are fallbacks too, resolved
; right-to-left: @constant @variant uses @variant in themes that define it and
; @constant otherwise. Later patterns win where two cover the same bytes, so
; broad rules come first.

(identifier) @variable

; The implicit parameter of a function value without a parameter list.
((identifier) @variable.special
 (#eq? @variable.special "it"))

(parameter name: (identifier) @variable.parameter)
(function_value_parameter name: (identifier) @variable.parameter)

(field_declaration name: (identifier) @property)
(field_expression field: (identifier) @property)
(field_initializer name: (identifier) @property)
(storage_name field: (identifier) @property)

(namespace_declaration name: (identifier) @namespace)
(namespace_alias name: (identifier) @namespace)
(namespace_alias target: (identifier) @namespace)
(import_path (identifier) @namespace)
(scoped_identifier namespace: (identifier) @namespace)

(function_declaration name: (identifier) @function)
(function_declaration name: (scoped_identifier name: (identifier) @function))
(extern_member name: (identifier) @function)
(extern_member name: (scoped_identifier name: (identifier) @function))
(call_expression function: (identifier) @function.call)
(call_expression function: (scoped_identifier name: (identifier) @function.call))
; A call through a dot is a method call or a call of a free function by UFCS.
(call_expression function: (field_expression field: (identifier) @function.method.call))
(return_expression target: (identifier) @function)
(return_expression target: (scoped_identifier name: (identifier) @function))

(struct_declaration name: (identifier) @type)
(struct_declaration name: (scoped_identifier name: (identifier) @type))
(enum_declaration name: (identifier) @type)
(enum_declaration name: (scoped_identifier name: (identifier) @type))
(type_alias_declaration name: (identifier) @type)
(type_alias_declaration name: (scoped_identifier name: (identifier) @type))
(type_parameter name: (identifier) @type)
(named_type name: (identifier) @type)
(named_type name: (scoped_identifier name: (identifier) @type))
(struct_literal name: (identifier) @type)
(struct_literal name: (scoped_identifier name: (identifier) @type))
(variant_constant name: (identifier) @type)
(variant_constant name: (scoped_identifier name: (identifier) @type))
(primitive_type) @type.builtin

(enum_variant name: (identifier) @constant @variant)
(variant_type variant: (identifier) @constant @variant)
(struct_literal variant: (identifier) @constant @variant)
(variant_constant variant: (identifier) @constant @variant)
(variant_pattern variant: (identifier) @constant @variant)
(pattern_list (identifier) @constant @variant)
(range_pattern (identifier) @constant @variant)
(negative_pattern (identifier) @constant @variant)

; A payload-less variant: `Shape.Dot`. Types and variants are PascalCase by
; convention, which separates them from a field read.
((field_expression value: (identifier) @type field: (identifier) @constant @variant)
 (#match? @type "^[A-Z]")
 (#match? @constant "^[A-Z]"))

(self) @variable.special
(wildcard_pattern) @variable.special

(function_modifier) @keyword.modifier
"root" @keyword.modifier
(extern_block "extern" @keyword.modifier)

; The queries of a const if condition, keywords there only.
(const_query name: (identifier) @keyword)

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
  "block"
  "defer"
  "fields"
  "variants"
  "types"
  "in"
  "upto"
] @keyword

"as" @keyword.operator

[
  "import"
  "from"
] @keyword.import

"return" @keyword.return

[
  "if"
  "else"
  "match"
  "guard"
] @keyword.conditional

[
  "while"
  "for"
  "loop"
  "break"
  (continue_expression)
] @keyword.repeat

(boolean_literal) @boolean
(null) @constant.builtin
(int_literal) @number
(float_literal) @number.float
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

; Builtins at the end, so they win over the generic call patterns. This rule
; is Zed-only; the grammar's query leaves builtins as plain calls.
((call_expression function: (identifier) @function.builtin)
 (#any-of? @function.builtin
   "print" "str" "format" "assert" "abort" "exit" "hardware_threads"
   "thread_spawn" "thread_wait" "qput" "qget" "qpoll" "default" "copy"
   "to_bytes" "bytes_of" "from_bytes" "embed_shader" "embed_file" "index_of"
   "push" "append" "pop" "pop_n" "resize" "clear" "alloc_index" "alloc_ref"
   "free" "alloc_slice" "realloc_slice" "free_slice"))

(line_comment) @comment
(block_comment) @comment
