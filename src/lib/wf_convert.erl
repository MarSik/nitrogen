% Nitrogen Web Framework for Erlang
% Copyright (c) 2008-2009 Rusty Klophaus
% See MIT-LICENSE for licensing information.

-module (wf_convert).
-export ([
	clean_lower/1,
	to_list/1, 
	to_atom/1, 
	to_binary/1, 
	to_integer/1,
	html_encode/1, html_encode/2, html_encode_whites/1
]).

-include ("wf.inc").

%%% CONVERSION %%%

clean_lower(L) -> string:strip(string:to_lower(to_list(L))).

to_list(undefined) -> [];
to_list(L) when ?IS_STRING(L) -> L;
to_list(L) when is_integer(L) -> integer_to_list(L);
to_list(L) when is_binary(L) -> binary_to_list(L);
to_list(L) when is_atom(L) -> atom_to_list(L);
to_list(L) when is_list(L) ->
    SubLists = [inner_to_list(X) || X <- L],
    lists:flatten(SubLists).

inner_to_list(L) when is_integer(L) -> L;
inner_to_list(L) -> to_list(L).

to_atom(A) when is_atom(A) -> A;
to_atom(B) when is_binary(B) -> to_atom(binary_to_list(B));
to_atom(I) when is_integer(I) -> to_atom(integer_to_list(I));
to_atom(L) when is_list(L) -> list_to_atom(binary_to_list(list_to_binary(L))).

to_binary(A) when is_atom(A) -> to_binary(atom_to_list(A));
to_binary(B) when is_binary(B) -> B;
to_binary(I) when is_integer(I) -> to_binary(integer_to_list(I));
to_binary(L) when is_list(L) -> list_to_binary(L).

to_integer(A) when is_atom(A) -> to_integer(atom_to_list(A));
to_integer(B) when is_binary(B) -> to_integer(binary_to_list(B));
to_integer(I) when is_integer(I) -> I;
to_integer(L) when is_list(L) -> list_to_integer(L).

%%% HTML ENCODE %%%

html_encode(L) ->
    html_encode_core(wf:to_list(L)).

html_encode(L, false) -> wf:to_list(L);
html_encode(L, true) -> html_encode_core(wf:to_list(L));
html_encode(L, whites) -> html_encode_whites(wf:to_list(L)).	

html_encode_core([]) -> [];
html_encode_core([H|T]) ->
	case H of
		$< -> "&lt;" ++ html_encode_core(T);
		$> -> "&gt;" ++ html_encode_core(T);
		$" -> "&quot;" ++ html_encode_core(T);
		$' -> "&#39;" ++ html_encode_core(T);
		$& -> "&amp;" ++ html_encode_core(T);
		_ -> [H|html_encode_core(T)]
	end.

html_encode_whites([]) -> [];
html_encode_whites([H|T]) ->
	case H of
		$\s -> "&nbsp;" ++ html_encode_whites(T);
		$\t -> "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" ++ html_encode_whites(T);
		$< -> "&lt;" ++ html_encode_whites(T);
		$> -> "&gt;" ++ html_encode_whites(T);
		$" -> "&quot;" ++ html_encode_whites(T);
		$' -> "&#39;" ++ html_encode_whites(T);
		$& -> "&amp;" ++ html_encode_whites(T);
		$\n -> "<br>" ++ html_encode_whites(T);
		_ -> [H|html_encode_whites(T)]
	end.

