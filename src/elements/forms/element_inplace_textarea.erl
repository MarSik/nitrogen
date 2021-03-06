% Nitrogen Web Framework for Erlang
% Copyright (c) 2008-2009 Rusty Klophaus
% See MIT-LICENSE for licensing information.

-module (element_inplace_textarea).
-include ("wf.inc").
-compile(export_all).

reflect() -> record_info(fields, inplace_textarea).

render(ControlID, Record) -> 
	% Get vars...
	OKButtonID = wf:temp_id(),
	CancelButtonID = wf:temp_id(),
	ViewPanelID = wf:temp_id(),
	EditPanelID = wf:temp_id(),
	LabelID = wf:temp_id(),
	MouseOverID = wf:temp_id(),
	TextBoxID = wf:temp_id(),
	Tag = Record#inplace_textarea.tag,
	OriginalText = Record#inplace_textarea.text,
	
	% Set up the events...
	Controls = {ViewPanelID, LabelID, EditPanelID, TextBoxID},
	OKEvent = #event { delegate=?MODULE, postback={ok, Controls, Tag, Record#inplace_textarea.delegate} },
	CancelEvent = #event { delegate=?MODULE, postback={cancel, Controls, Tag, OriginalText, Record#inplace_textarea.delegate} },
	
	% Create the view...
	Text = Record#inplace_textarea.text,
	Terms = #panel { 
		class="inplace_textarea " ++ wf:to_list(Record#inplace_textarea.class),
		style=Record#inplace_textarea.style,
		body = [
			#panel { id=ViewPanelID, class="view", body=[
				#span { id=LabelID, class="label", text=Text, html_encode=Record#inplace_textarea.html_encode, actions=[
					#buttonize { target=ViewPanelID }
				]},
				#span { id=MouseOverID, class="instructions", text="Klikněte, pokud chcete změnit text.", actions=#hide{} }
			], actions = [
				#event { type=click, actions=[
					#hide { target=ViewPanelID },
					#show { target=EditPanelID },
					#script { script = wf:f("obj('~s').focus(); obj('~s').select();", [TextBoxID, TextBoxID]) }
				]},
				#event { type=mouseover, target=MouseOverID, actions=#show{} },
				#event { type=mouseout, target=MouseOverID, actions=#hide{} }
			]},
			#panel { id=EditPanelID, class="edit", body=[
				#textarea { id=TextBoxID, text=Text }, "<br/>",
				#button { id=OKButtonID, text="Uložit", actions=OKEvent#event { type=click } },
				#button { id=CancelButtonID, text="Zrušit", actions=CancelEvent#event { type=click } }
			]}
		]
	},
	
	case Record#inplace_textarea.start_mode of
		view -> wf:wire(EditPanelID, #hide{});
		edit -> 
			wf:wire(ViewPanelID, #hide{}),
			wf:wire(TextBoxID, "obj('me').focus(); obj('me').select();")
	end,
	
	wf:wire(OKButtonID, TextBoxID, #validate { attach_to=CancelButtonID, validators=Record#inplace_textarea.validators }),
	
	element_panel:render(ControlID, Terms).

event({ok, {ViewPanelID, LabelID, EditPanelID, TextBoxID}, Tag, Delegated}) -> 
	[Value] = wf:q(TextBoxID),
	Delegate = case Delegated of
	    undefined -> wf_platform:get_page_module();
	    D -> D
	end,
	Value1 = Delegate:inplace_textarea_event(Tag, Value),
	wf:update(LabelID, Value1),
	wf:set(TextBoxID, Value1),
	wf:wire(EditPanelID, #hide {}),
	wf:wire(ViewPanelID, #show {}),
	ok;

event({cancel, {ViewPanelID, _LabelID, EditPanelID, TextBoxID}, _Tag, OriginalText, _Delegated}) ->
	wf:set(TextBoxID, OriginalText),
	wf:wire(EditPanelID, #hide {}),
	wf:wire(ViewPanelID, #show {}),
	ok;	

event(_Tag) -> ok.
