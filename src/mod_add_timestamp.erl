%% name of module must match file name
-module(mod_add_timestamp).

-author("Johan Vorster").

%% Every ejabberd module implements the gen_mod behavior
%% The gen_mod behavior requires two functions: start/2 and stop/1
-behaviour(gen_mod).

%% public methods for this module
-export([start/2, stop/1, on_filter_packet/1]).

%% included for writing to ejabberd log file
-include("ejabberd.hrl").
-include("logger.hrl").

start(_Host, _Opt) ->
    ?INFO_MSG("starting mod_add_timestamp", []),
    ejabberd_hooks:add(filter_packet, global, ?MODULE, on_filter_packet, 120).

stop(_Host) ->
    ?INFO_MSG("stopping mod_add_timestamp", []),
    ejabberd_hooks:delete(filter_packet, global, ?MODULE, on_filter_packet, 120).

on_filter_packet({From, To, XML} = Packet) ->

    Type = xml:get_tag_attr_s(<<"type">>, XML),
    DataTag = xml:get_subtag(XML, <<"data">>),
    OldTimestamp = xml:get_subtag(XML, <<"timestamp">>),

    %% Add timestamp to chat message and where no DataTag exist
    case ((Type =:= <<"chat">>) or (Type =:= <<"groupchat">>))
         andalso DataTag =:= false
         andalso OldTimestamp =:= false of
    true ->
        ?INFO_MSG("on_filter_packet Chat = True", []),
        ?INFO_MSG("on_filter_packet ~p~n", [Packet]),
        ?INFO_MSG("on_filter_packet Message Type ~p~n",[Type]),
        ?INFO_MSG("on_filter_packet DataTag ~p~n",[DataTag]),

        Timestamp = now_to_milliseconds(erlang:now()),
        FlatTimeStamp = lists:flatten(io_lib:format("~p", [Timestamp])),
        ?INFO_MSG("on_filter_packet FlatTimestamp ~p~n", [FlatTimeStamp]),

        XMLTag = {xmlel,<<"timestamp">>, [], [{xmlcdata, list_to_binary(FlatTimeStamp)}]},
        TimeStampedPacket = xml:append_subtags(XML, [XMLTag]),
        ?INFO_MSG("on_filter_packet TimeStamped Packet ~p~n", [TimeStampedPacket]),

        ReturnPacket = {From, To, TimeStampedPacket},
        %?INFO_MSG("on_filter_packet Return Packet ~p~n", [ReturnPacket]),

        Return = ReturnPacket;

        %?INFO_MSG("on_filter_packet TRUE Return ~p~n", [Return]);
    false ->
        %?INFO_MSG("on_filter_packet Chat = False", []),
        Return = Packet
        %?INFO_MSG("on_filter_packet ELSE Return ~p~n", [Return])
    end,

    %?INFO_MSG("on_filter_packet Return Value ~p~n", [Return]),

    Return.

now_to_milliseconds({Mega, Sec, Micro}) ->
    %%Epoch time in milliseconds from 1 Jan 1970
    ?INFO_MSG("now_to_milliseconds Mega ~p Sec ~p Micro ~p~n", [Mega, Sec, Micro]),
    (Mega*1000000 + Sec)*1000 + Micro div 1000.

