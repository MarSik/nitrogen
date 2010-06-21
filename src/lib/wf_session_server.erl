% Nitrogen Web Framework for Erlang
% Copyright (c) 2008-2009 Rusty Klophaus
% Contributions from Dave Peticolas
% See MIT-LICENSE for licensing information.

-module(wf_session_server).

-behaviour(gen_server).

%% API
-export([start_link/0, sign_key/1, get_session/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
		 terminate/2, code_change/3]).

-export([create_table/1]).

-define(SERVER, ?MODULE). 

%% Mnesia session store structures and funcs
-record(nitrogen_session, {unique, pid}).

create_table(Nodes) ->
	mnesia:create_table(nitrogen_session,
		[{ram_copies, Nodes},
		 {type, set},
		 {attributes, record_info(fields, nitrogen_session)}
                ]).

start_link() ->
	gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

% For use by wf_session only.
sign_key(Unique) ->
	gen_server:call(?SERVER, {sign_key, Unique}).

% For use by wf_session only.
get_session(Unique) ->
	gen_server:call(?SERVER, {get_session, Unique}).


%%% gen_server callbacks %%%

init([]) ->
	ok = mnesia:start(),
	create_table([node()]),
	ok = mnesia:wait_for_tables([nitrogen_session],60000),
	{ok, dict:new()}.

handle_call({sign_key, Unique0}, _From, Map) ->
        Unique = wf:to_list(Unique0),
	{ok, Pid} = wf_session_sup:start_session(),
	ServerPid = self(),
	spawn_link(fun () -> session_monitor(ServerPid, Pid, Unique) end),
	SessionRec = #nitrogen_session{unique = Unique, pid = Pid},
	CommitFunc = fun() -> mnesia:write(SessionRec) end,
	{atomic, _} = mnesia:transaction(CommitFunc),
	{reply, {ok, Pid}, Map};

handle_call({get_session, Unique0}, _From, Map) ->
        Unique = wf:to_list(Unique0),
	F = fun() ->
		mnesia:read({nitrogen_session, Unique})
	    end,
	Pid = case mnesia:transaction(F) of
	 {atomic, []} -> undefined;
         {atomic, [P]} -> P#nitrogen_session.pid
	end,        
	{reply, {ok, Pid}, Map}.

handle_cast({remove_session, Unique0}, Map) ->
        Unique = wf:to_list(Unique0),
	F = fun() ->
		mnesia:delete({nitrogen_session, Unique})
	end,
	{atomic, _} = mnesia:transaction(F),
	{noreply, Map};

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

session_monitor(ServerPid, SessionPid, Unique) ->
	Ref = erlang:monitor(process, SessionPid),
	receive
		{'DOWN', Ref, _, _, _} ->
			gen_server:cast(ServerPid, {remove_session, Unique})
	end.
