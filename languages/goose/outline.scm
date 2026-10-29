(namespace_declaration
  "namespace" @context
  name: (identifier) @name) @item

(import_declaration
  "import" @context
  path: (import_path) @name) @item

(struct_declaration
  "struct" @context
  name: (identifier) @name) @item

(struct_declaration
  "struct" @context
  name: (scoped_identifier name: (identifier) @name)) @item

(enum_declaration
  "enum" @context
  name: (identifier) @name) @item

(enum_variant
  name: (identifier) @name) @item

(type_alias_declaration
  "type" @context
  name: (identifier) @name) @item

(type_alias_declaration
  "type" @context
  name: (scoped_identifier name: (identifier) @name)) @item

(function_declaration
  (function_modifier)? @context
  ["fn" "thread_fn"] @context
  name: (identifier) @name) @item

(function_declaration
  (function_modifier)? @context
  ["fn" "thread_fn"] @context
  name: (scoped_identifier name: (identifier) @name)) @item

(field_declaration
  name: (identifier) @name) @item

(extern_member
  "fn" @context
  name: (identifier) @name) @item

; Doc comments would annotate the item that follows, but Goose has no
; documentation-comment syntax distinct from `//`.
