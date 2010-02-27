-module (quickstart_inets_app).
-export ([start/2, stop/0, do/1]).
-include ("wf.inc").
-define(PORT, 8000).


start(_, _) ->
  Nodes = ['nitrogen@127.0.0.1', 'nitrogen_mochiweb@127.0.0.1'],
	mnesia_process_registry_handler:start(Nodes),
	inets:start(),
	{ok, Pid} = inets:start(httpd, [
		{port, ?PORT},
		{server_name, "nitrogen"},
		{server_root, "."},
		{document_root, "./wwwroot"},
		{modules, [?MODULE]},
		{mime_types, [{"css", "text/css"}, {"js", "text/javascript"}, {"html", "text/html"}]}
	]),
	link(Pid),
	{ok, Pid}.
	
stop() ->
	httpd:stop_service({any, ?PORT}),
	ok.
	
do(Info) ->
	RequestBridge = simple_bridge:make_request(inets_request_bridge, Info),
	ResponseBridge = simple_bridge:make_response(inets_response_bridge, Info),
	nitrogen:init_request(RequestBridge, ResponseBridge),
	nitrogen:run().