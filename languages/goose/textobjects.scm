(function_declaration
  body: (block) @function.inside) @function.around

(extern_member) @function.around

(struct_declaration
  body: (field_declaration_list) @class.inside) @class.around

(enum_declaration) @class.around

(line_comment)+ @comment.around
(block_comment) @comment.around
