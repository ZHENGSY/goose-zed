; `fn main` gets a run button, which runs the file with the `goose run` task
; from tasks.json.
(
  (function_declaration
    name: (identifier) @run
    (#eq? @run "main"))
  (#set! tag goose-run)
)
