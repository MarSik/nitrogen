% Nitrogen Web Framework for Erlang
% Copyright (c) 2008-2009 Rusty Klophaus
% See MIT-LICENSE for licensing information.

-module (element_upload).
-include ("wf.inc").
-compile(export_all).

reflect() -> record_info(fields, upload).

% TODO 
% - Figure out how to access the parent document.
% - Issue a postback on the parent document with the identifier of the file.
% - Handle the postback and call an event on the page module.
% - Does document.parentNode always work in an iframe?

render(ControlID, Record) ->
	ShowButton = Record#upload.show_button,
	ButtonText = Record#upload.button_text,
	FormID = wf:temp_id(),
        LoadingID = wf:temp_id(),
	IFrameID = wf:temp_id(),
	SubmitJS = wf:f("jQuery(obj('~s')).hide(); jQuery(obj('~s')).show(); Nitrogen.$upload(obj('~s'));", [FormID, LoadingID, FormID]),
	PostbackInfo = action_event:make_postback_info(Record#upload.tag, upload, ControlID, ControlID, ?MODULE),
	
	% If the button is invisible, then start uploading when the user selects a file.
	wf:wire(ControlID, #event { show_if=(not ShowButton), type=change, actions=SubmitJS }),
	
	% Render the controls and hidden iframe...
        LoadingContent = [
                wf_tags:emit_tag(p, "Soubor se přenáší, nezavírejte prosím okno a neodcházejte z této stránky.", [])
        ],

	FormContent = [
		wf_tags:emit_tag(input, [
			{id, ControlID},
			{name, ControlID},
			{type, file}
		]),	
	
		wf_tags:emit_tag(input, [
			{name, postbackInfo},
			{type, hidden},
			{value, PostbackInfo}
		]),
		
		wf_tags:emit_tag(input, [
			{name, domState},
			{type, hidden},
			{value, ""}
		]),

		wf_tags:emit_tag(input, [
			{name, formID},
			{type, hidden},
			{value, FormID}
		]),

		wf_tags:emit_tag(input, [
			{name, loadingID},
			{type, hidden},
			{value, LoadingID}
		]),
		
		wf:render(#button { show_if=ShowButton, text=ButtonText, actions=#event { type=click, actions=SubmitJS } })
	],
	
	[
                wf_tags:emit_tag('div', LoadingContent, [
                        {id, LoadingID},
                        {style, "display: none;"}
                ]),

		wf_tags:emit_tag(form, FormContent, [
			{id, FormID},
			{name, FormID}, 
			{method, 'POST'},
			{enctype, "multipart/form-data"},
			{target, IFrameID}
		]),
		
		wf_tags:emit_tag(iframe, [], [
			{id, IFrameID},
			{name, IFrameID},
			{style, "display: none; width: 300px; height: 100px;"}
		])
	].
	
event({upload, Tag, Filename, LocalFileData, FormID, LoadingID}) -> 
	Delegate = wf_platform:get_page_module(),
        wf:wire(FormID, #show{}),
        wf:wire(LoadingID, #hide{}),
	Delegate:upload_event(Tag, Filename, LocalFileData),
	ok.
