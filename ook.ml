open Unix
   
(* 
 * Global mutable vars to handle arg list parsing.
 *)
let show = ref false
let quiet = ref false
let add = ref false
let command = ref [] 
            

(*
 * Each line in the command file can be a command, a comment 
 * or something else that we will just ignore.
 *)
type command_line = 
  | Command of string * string
  | Comment of string
  | Duff
  

(*
 * Sets the command to run from the arglist.
 *)
let set_command c = command := List.append !command [c]
                  

(*
 * Read a file and catch the Eof.
 *)
let read_line file =
  try
    Some (input_line file)
  with End_of_file ->
    None
       

(*
 * The ook file is ~/.ook
 * This is where all the command snippets are stored.
 *)
let command_file = (getenv "HOME" ^ "/.ook") 
                 

(*
 * Does something (whatever function is passed as a parmeter) with the .ook file.
 *)
let with_command_file fn =
  let f = open_in command_file in
  try
    fn f 
  with e ->
        close_in_noerr f;
        raise e
        

(*
 * Checks if the string starts with the given character.
 * Doesn't error if it is an empty string.
 *)
let starts_with str char = 
  (String.length str > 0) && (String.get str 0 = char)
  

(* 
 * Take the line in the command file (blah=do stuff)
 * returns a tuple of the command name (blah) and the command 
 *)
let extract_command line = 
  let trimmed = String.trim line in
  if starts_with trimmed '#'
  then Comment line
  else 
    let split = String.split_on_char '=' trimmed in
    if List.length split > 1
    then Command (List.hd split, String.concat "=" (List.tl split))
    else Duff


(*
 * Dumps the commands to stdout.
 *)
let print_commands () =
  let rec print_lines f =
    match read_line f with
    | Some (line) -> 
      (match extract_command line with
       | Command (name, command) ->
         print_endline name;
         print_lines f |> ignore;
       | _ -> print_lines f |> ignore);
    | None -> () 
  in
  with_command_file print_lines
                

(*
 * Retrieves the command from our .ook file.
 *
 *)
let get_command command = 
    let rec match_line f =
      match read_line f with
      | Some (line) -> 
        (match extract_command line with
         | Command (name, command') when name = command ->
           Some(command')
         | _ -> match_line f)
      | None -> None
    in
    with_command_file match_line
    

(*
 * Substitutes parameters.
 * If a given command has $OOKn (where n is a number starting from 0) then 
 * any additional parameters passed into ook are substituted.
 *
 *)
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
  

(*
 * Adds the given command to the ook file
 *)
let add_command command =
  let f = open_out_gen [Open_creat; Open_text; Open_append] 0o600 command_file in
  try
    output_string f "\n";
    output_string f ((List.hd command) ^ "=" ^ (String.concat " " (List.tl command)));
    flush f;
    close_out f;
  with e ->
        close_out_noerr f;
        raise e
         

(*
 * Parse the arglist and do the thing.
 *)
let main = 
  begin
    let speclist = [ ("-s", Arg.Set (show), "Show the available commands")
                   ; ("-a", Arg.Set (add), "Add a new command")
                   ; ("-q", Arg.Set (quiet), "Show the command that would run, but don't actually run it")] in
    let usage = "usage: ook [option] command" in
    
    Arg.parse speclist set_command usage;
    
    if !show then
      print_commands ()
    else if !add then
      add_command !command
    else if !quiet then
        match get_command (List.hd !command) with
        | Some(c) -> let to_run = substitute c (List.tl !command) in
                     print_endline (ANSITerminal.sprintf [ANSITerminal.green] "%s" to_run);
        | None -> print_endline (ANSITerminal.sprintf [ANSITerminal.red] "%s" "Duff command");
    else if !command != [] then
        match get_command (List.hd !command) with
        | Some(c) -> let to_run = substitute c (List.tl !command) in
                     print_endline (ANSITerminal.sprintf [ANSITerminal.green] "%s" to_run);
                     system to_run
                     |> ignore
        | None -> print_endline (ANSITerminal.sprintf [ANSITerminal.red] "%s" "Duff command");
    else 
        Arg.usage speclist usage |> ignore
    
  end
