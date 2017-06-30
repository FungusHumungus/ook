open Unix
   
let show = ref false
let quiet = ref false
let add = ref false
let command = ref [] 
            
let set_command c = command := List.append !command [c]
                  
let read_line file =
  try
    Some (input_line file)
  with End_of_file ->
    None
       
let command_file = (getenv "HOME" ^ "/.ook") 
                 
let with_command_file fn =
  let f = open_in command_file in
  try
    fn f 
  with e ->
        close_in_noerr f;
        raise e
        
(* Take the line in the command file (blah=do stuff) 
returns a tuple of the command name (blah) and the command *)
let extract_command line = 
  let split = String.split_on_char '=' line in
  (List.hd split, String.concat "=" (List.tl split))
                       
let print_commands () =
  let rec print_lines f =
    match read_line f with
    | Some (line) -> let (name, command) = extract_command line in
                     print_endline name;
                     ignore (print_lines f);
    | None -> () 
  in
  with_command_file print_lines
                 
let get_command command = 
    let rec match_line f =
      match read_line f with
      | Some (line) -> let (name, command') = extract_command line in
                       if name = command then
                         Some(command')
                       else
                         match_line f
      | None -> None
    in
    with_command_file match_line
    
    
let substitute command subs = 
  let rec subst_idx command' idx =
    if (List.length subs > idx) then
      let regexp = Str.regexp ("\\$OOK" ^ (string_of_int idx)) in
      let command'' = Str.global_replace regexp (List.nth subs idx) command' in
      subst_idx command'' (idx + 1)
    else
      command'
  in
  subst_idx command 0
  
let add_command () =
  let f = open_out_gen [Open_creat; Open_text; Open_append] 0o600 command_file in
  try
    output_string f "\n";
    output_string f ((List.hd !command) ^ "=" ^ (String.concat " " (List.tl !command)));
    flush f;
    close_out f;
  with e ->
        close_out_noerr f;
        raise e
         
let main = 
  begin
    let speclist = [ ("-s", Arg.Set (show), "Show the available commands")
                   ; ("-a", Arg.Set (add), "Add a new command")
                   ; ("-q", Arg.Set (quiet), "Show the command that would run, but don't actually run it")] in
    let usage = "Runs command line snippets" in
    
    Arg.parse speclist set_command usage;
    
    if !show then
      print_commands ()
    else if !add then
      add_command ()
    else if !quiet then
        match get_command (List.hd !command) with
        | Some(c) -> let to_run = substitute c (List.tl !command) in
                     print_endline (ANSITerminal.sprintf [ANSITerminal.green] "%s" to_run);
        | None -> print_endline (ANSITerminal.sprintf [ANSITerminal.red] "%s" "Duff command");
    else
      begin
        match get_command (List.hd !command) with
        | Some(c) -> let to_run = substitute c (List.tl !command) in
                     print_endline (ANSITerminal.sprintf [ANSITerminal.green] "%s" to_run);
                     system c
                     |> ignore
        | None -> print_endline (ANSITerminal.sprintf [ANSITerminal.red] "%s" "Duff command");
      end
    
  end
